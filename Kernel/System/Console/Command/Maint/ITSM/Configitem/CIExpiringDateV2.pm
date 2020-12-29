# --
#
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
#running from CONSOLE OR DAEMON
#
##REF http://doc.otrs.com/doc/api/otrs/6.0/Perl/index.html
#
# Example: bin/otrs.Console.pl Maint::ITSM::Configitem::CIExpiringDateV2 --class Computer --class Hardware --date-field WarrantyExpirationDate --depl-state Production --depl-state Planned --depl-state-after Review --check-period 1 --queue Raw

package Kernel::System::Console::Command::Maint::ITSM::Configitem::CIExpiringDateV2;

use strict;
use warnings;

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
        Name        => 'class',
        Description => "Specify the config item class which this check should be perform. (Accept multiple class)",
        Required    => 1,
        HasValue    => 1, 
		ValueRegex  => qr/.*/smx,
		Multiple    => 1,
    );
	
	$Self->AddOption(
        Name        => 'depl-state',
        Description => "Specify the config item deployment state which this check should be perform. (Accept multiple deployment state)",
        Required    => 1,
        HasValue    => 1,
		ValueRegex  => qr/.*/smx,
		Multiple    => 1,
    );
	
	$Self->AddOption(
        Name        => 'date-field',
        Description => "Specify the config item date field name that determine expiring date.",
        Required    => 1,
        HasValue    => 1, 
		ValueRegex  => qr/.*/smx,
    );
	
	$Self->AddOption(
        Name        => 'check-period',
        Description => "Specify the lookup range (from 0 to 3) in month. 0 = current month, 1 = next 1 month, 2 = next 2 month, 3 = next 3 month",
        Required    => 1,
        HasValue    => 1, 
		ValueRegex  => qr/.*/smx,
    );
	
	$Self->AddOption(
        Name        => 'depl-state-after',
        Description => "Specify the config item deployment state to be set after the check.",
        Required    => 1,
        HasValue    => 1,
		ValueRegex  => qr/.*/smx,
    );
	
	$Self->AddOption(
        Name        => 'queue',
        Description => "Ticket will be create in the mention queue if this parameter is being used",
        Required    => 0,
        HasValue    => 1,  
		ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;
	
	my @Class = @{ $Self->GetOption('class') // [] }; 					#E.g:	--class Computer --class Software
	my @DeplState = @{ $Self->GetOption('depl-state') // [] }; 			#E.g:	--depl-state Production --depl-state Planned
	my $DateField = $Self->GetOption('date-field'); 					#E.g: 	--date-field WarrantyExpirationDate
	
	my $CheckPeriod = $Self->GetOption('check-period'); 				#E.g:	--check-before 1
	my $DeplStateAfter = $Self->GetOption('depl-state-after'); 			#E.g:	--depl-state-after Review
	my $Queue = $Self->GetOption('queue') // '';						#E.g:	--queue Misc
	
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
	
	#get class id based on class name
	my @ClassIDs;
	foreach my $ClassName (@Class)
	{
		my $ClassID = $GeneralCatalogObject->ItemGet(
			Class => 'ITSM::ConfigItem::Class',
			Name  => $ClassName,
		);
		
		push @ClassIDs, $ClassID->{ItemID};
	}
	
	#get deployment state id based on deployment state name
	my @DeplStateIDs;
	foreach my $DeplStateName (@DeplState)
	{
		my $DeplStateID = $GeneralCatalogObject->ItemGet(
			Class => 'ITSM::ConfigItem::DeploymentState',
			Name  => $DeplStateName,
		);
		
		push @DeplStateIDs, $DeplStateID->{ItemID};
	}

	#create current time based on default timezone
	my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            TimeZone =>  Kernel::System::DateTime->SystemTimeZoneGet(), 
        }
    );

	#
	my $CurMonth;
	my $DateTimeString1 = '1989-12-'; #assign previous year values;
	my $DateTimeString2 = '1989-12-'; #assign previous year values
	my $DateTimeString3 = '1989-12-'; #assign previous year values
	
	if ( $CheckPeriod eq 0 )
	{
		$CurMonth = $DateTimeObject->Format( Format => '%Y-%m-' );
	}
	elsif ( $CheckPeriod eq 1 )
	{
		$CurMonth = $DateTimeObject->Format( Format => '%Y-%m-' );
		
		my $Success1 = $DateTimeObject->Add( Months => 1, );
		$DateTimeString1 = $DateTimeObject->Format( Format => '%Y-%m-' );	
	}
	elsif ( $CheckPeriod eq 2 )
	{
		
		$CurMonth = $DateTimeObject->Format( Format => '%Y-%m-' );
		
		my $Success1 = $DateTimeObject->Add( Months => 1, );
		$DateTimeString1 = $DateTimeObject->Format( Format => '%Y-%m-' );
		
		my $Success2 = $DateTimeObject->Add( Months => 1, );
		$DateTimeString2 = $DateTimeObject->Format( Format => '%Y-%m-' );	
	}
	
	elsif ( $CheckPeriod eq 3 )
	{
		$CurMonth = $DateTimeObject->Format( Format => '%Y-%m-' );
		
		my $Success1 = $DateTimeObject->Add( Months => 1, );
		$DateTimeString1 = $DateTimeObject->Format( Format => '%Y-%m-' );
		
		my $Success2 = $DateTimeObject->Add( Months => 1, );
		$DateTimeString2 = $DateTimeObject->Format( Format => '%Y-%m-' );	
		
		my $Success3 = $DateTimeObject->Add( Months => 1, );
		$DateTimeString3 = $DateTimeObject->Format( Format => '%Y-%m-' );		
	}
	else
	{
		$Self->Print("<red>Invalid Check Before Period! Accept only 0 to 3</red>\n");
		return $Self->ExitCodeOk();
	}
	
	#check for ticket reminder shoulld be create or not based on sent Queue parameter
	my $CreateReminder = 0;
	my $QueueID;
	if ($Queue)
	{
		$QueueID = $Kernel::OM->Get('Kernel::System::Queue')->QueueLookup( Queue => $Queue );
		
		if ( !$QueueID)
		{
			$Self->Print("<red>Queue $Queue is not valid!</red>\n\n");
			return $Self->ExitCodeOk();
		}
		else
		{
			$CreateReminder = 1;
		}
	}
	
	#check for valid id of deployment state (after)
	my $DeplStateIDAfter = $GeneralCatalogObject->ItemGet(
		Class => 'ITSM::ConfigItem::DeploymentState',
		Name  => $DeplStateAfter,
	);
	
	if ( !$DeplStateIDAfter )
	{
		$Self->Print("<red>Deployment State (After) $DeplStateAfter is not valid!</red>\n\n");
		return $Self->ExitCodeOk();
	}
	
	$Self->Print("<yellow>Searching effected config item based on Class: " .join(', ', @Class)."...</yellow>\n\n");		
	my $ConfigItemIDs = $ConfigItemObject->ConfigItemSearchExtended(
		ClassIDs     => \@ClassIDs, 
		DeplStateIDs => \@DeplStateIDs,
		What => [
           # each array element is a and condition
           {
               # or condition in hash
               "[%]{'Version'}[%]{'$DateField'}[%]{'Content'}" => [$CurMonth.'*', $DateTimeString1.'*', $DateTimeString2.'*', $DateTimeString3.'*'],
		   },
       ],
	   PreviousVersionSearch => 0,
	
	);
	
	if (!@{$ConfigItemIDs})
	{
		$Self->Print("<red>No config item effected...</red>\n\n");
		return $Self->ExitCodeOk();
	}
	
	###this print return array
	#use Data::Dumper;
	#print Dumper($DeplStateIDAfter);
	
	foreach my $cid (@{$ConfigItemIDs}) 
	{
		my $LastVersion = $ConfigItemObject->VersionGet(
				ConfigItemID => $cid,
				XMLDataGet   => 1,
			);
		
		my $ShortVer = $LastVersion->{XMLData}->[1]->{Version}->[1];
		my $ExpirationDate = $ShortVer->{$DateField}->[1]->{Content};
		
		$Self->Print("<green>found 1...$LastVersion->{Number} => $LastVersion->{Name} with Date: $ExpirationDate. </green>");
		
		if ($CreateReminder)
		{
			$Self->Print("<green>Creating Reminder Ticket. </green>");
			##CREATE REMINDER TICKET
			my $TicketID = $TicketObject->TicketCreate(
				Title        => "Config Item for $LastVersion->{Number} || $LastVersion->{Name} is Expiring",
				Queue        => $Queue,            
				Lock         => 'unlock',
				Priority     => '3 normal',       
				State        => 'new',           
				Type          => $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Type::Default'),         
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
				##ForceNotificationToUserID => [ $PIC ],
			);
			
			#$Self->Print("<green>Link ticket with...$LastVersion->{Number} || $LastVersion->{Name}\n</green>");	
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
			
			$Self->Print("<green>Updating Deployment State to $DeplStateAfter\n</green>");
			my $VersionID = $ConfigItemObject->VersionAdd(
				ConfigItemID => $LastVersion->{ConfigItemID},
				Name         => $LastVersion->{Name},
				DefinitionID => $LastVersion->{DefinitionID},
				DeplStateID  => $DeplStateIDAfter->{ItemID},
				InciStateID  => $LastVersion->{InciStateID},
				XMLData      => $LastVersion->{XMLData},  # (optional)
				UserID       => 1,
			);
		
		}
		else
		{
			$Self->Print("<green>No reminder...Just updating Deployment State to $DeplStateAfter\n</green>");
			my $VersionID = $ConfigItemObject->VersionAdd(
				ConfigItemID => $LastVersion->{ConfigItemID},
				Name         => $LastVersion->{Name},
				DefinitionID => $LastVersion->{DefinitionID},
				DeplStateID  => $DeplStateIDAfter->{ItemID},
				InciStateID  => $LastVersion->{InciStateID},
				XMLData      => $LastVersion->{XMLData},  # (optional)
				UserID       => 1,
			);
		}
	}	

	$Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();

}

1;
