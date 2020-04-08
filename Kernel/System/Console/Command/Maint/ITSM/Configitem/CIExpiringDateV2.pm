#
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
#running from CONSOLE OR DAEMON
#
##REF http://doc.otrs.com/doc/api/otrs/6.0/Perl/index.html
package Kernel::System::Console::Command::Maint::ITSM::Configitem::CIExpiringDateV2;

use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use DateTime qw();
use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DateTime',
    'Kernel::System::Ticket',
    'Kernel::System::User',
);


sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Process Config Item contract that near expire.');
	
	$Self->AddOption(
        Name        => 'queue',
        Description => "Specify the queue name where the reminder ticket should be create (default: Misc).",
        Required    => 0,
        HasValue    => 1,  
		ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'ci-date-field',
        Description => "Specify the config item date field that determine expiring date.",
        Required    => 1,
        HasValue    => 1, 
		ValueRegex  => qr/.*/smx,
    );
	 $Self->AddOption(
        Name        => 'ci-mark-field',
        Description => "Specify the config item dropdown field that determine reminder should be create or not.",
        Required    => 1,
        HasValue    => 1,
		ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;
	
	my $Queue = $Self->GetOption('queue') // 'Misc';
	my $DateField = $Self->GetOption('ci-date-field'); #E.g: WarrantyExpirationDate
	my $MarkField= $Self->GetOption('ci-mark-field');  #E.g: RenewalAlert
	
	$Self->Print("<yellow>Process effected config item...</yellow>\n\n");
	#get config item asset object
	my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
	#get general catalog object
	my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
	#get ticket object
	my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
	#get article backend object
	my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(ChannelName => 'Phone');
	#get link object
	my $LinkObject = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
    my $CurMonth = $DateTimeObject->Format( Format => '%Y-%m-' );
	
	$Self->Print("<yellow>Searching effected config item...</yellow>\n\n");
	#search ci based on expire date = current month, renewal alert = yes
	my $ConfigItemIDs1 = $ConfigItemObject->ConfigItemSearchExtended(

        What => [                                                # (optional)
            # each array element is a and condition
            {
                # or condition in hash
                "[%]{'Version'}[%]{'$DateField'}[%]{'Content'}" => [$CurMonth.'*'],
			},
            {
                # or condition in hash
				# 37 is id of 'Yes' value (ITSM General Catalog - dropdown)
                "[%]{'Version'}[%]{'$MarkField'}[%]{'Content'}" => '37',
            },
        ],
		
		);
	
	##this print return array
	#print "Content-type: text/plain\n\n";
	#print Dumper($ConfigItemIDs1);
		
	my @found_config_item_id;
	push @found_config_item_id, @{$ConfigItemIDs1};
	
	if (!@found_config_item_id)
	{
	$Self->Print("<red>No config item effected...</red>\n\n");
	exit; 
	}
	
	foreach my $cid (@found_config_item_id) 
	{
		my $LastVersion = $ConfigItemObject->VersionGet(
				ConfigItemID => $cid,
				XMLDataGet   => 1,
			);
		
		$Self->Print("<green>found 1...$LastVersion->{Number} => $LastVersion->{Name}</green>\n\n");
		
		my $ShortVer = $LastVersion->{XMLData}->[1]->{Version}->[1];
		my $ExpirationDate = $ShortVer->{$DateField}->[1]->{Content};
		
		$Self->Print("<green>Creating reminder ticket for...$LastVersion->{Number} => $LastVersion->{Name}</green>\n\n");
		
		#Queue should be from param
		#CREATE REMINDER TICKET
		my $TicketID = $TicketObject->TicketCreate(
		Title        => "Config Item for $LastVersion->{Number} || $LastVersion->{Name} is Expiring",
		Queue        => $Queue,            
		Lock         => 'unlock',
		Priority     => '3 normal',       
		State        => 'new',           
		#Type          => 'Support',         
		#CustomerID   => $CustomerID,
		#CustomerUser => 'root@localhost',
		OwnerID      => 1,
		ResponsibleID => 1,
		UserID       => 1,
		);
		
		my $ArticleID = $ArticleBackendObject->ArticleCreate(
		TicketID             => $TicketID,                             
		SenderType           => 'system',                          
		IsVisibleForCustomer => 0,                                
		UserID               => 1,                              
		From        => 'root@localhost',                       
		To          => $Queue,            				
		Subject     => "Config Item for $LastVersion->{Number} || $LastVersion->{Name} is Expiring", 
		Body        => "Dear team,<br/><br/>
		Take note that Config Item below will be expiry soon. <br/><br>
		Number: $LastVersion->{Number}<br/>
		Name: $LastVersion->{Name}<br/>
		Expiry Date: $ExpirationDate<br/><br/>",                                    
		ContentType => 'text/html; charset=utf8',
		Loop        => 0,
		HistoryType    => 'EmailCustomer',  # Move|AddNote|PriorityUpdate|WebRequestCustomer|...
		HistoryComment => 'Config Item Expiring',
		NoAgentNotify  => 0,            # if you don't want to send agent notifications, set to 1
		#ForceNotificationToUserID => [ $PIC ],
		);
		
		
		$Self->Print("<green>Update renewal alert to No for...$LastVersion->{Number} || $LastVersion->{Name}</green>\n\n");
		#push update new renewal alert value to no (38)
		$ShortVer->{$MarkField}->[1]->{Content} = "38";
		
		my $VersionID = $ConfigItemObject->VersionAdd(
        ConfigItemID => $LastVersion->{ConfigItemID},
        Name         => $LastVersion->{Name},
        DefinitionID => $LastVersion->{DefinitionID},
        DeplStateID  => $LastVersion->{DeplStateID},
        InciStateID  => $LastVersion->{InciStateID},
        XMLData      => $LastVersion->{XMLData},  # (optional)
        UserID       => 1,
		);
	    	
		$Self->Print("<green>Link ticket with...$LastVersion->{Number} || $LastVersion->{Name}</green>\n\n");	
		##Link CI with the new created ticket	
		my $True = $LinkObject->LinkAdd(
        SourceObject => 'Ticket',
        SourceKey    => $TicketID,
        TargetObject => 'ITSMConfigItem',
        TargetKey    => $LastVersion->{ConfigItemID},
        Type         => 'RelevantTo',
        State        => 'Valid',
        UserID       => 1,
		);
		
	
	}  #CLOSE FOREACH $cid
	
	$Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();

}

1;
