# OTRS-Config-Item-Notification  
- Built for OTRS CE v 6.0.x  
- Check Config Item expiring date and if within current month and mark with alert 'Yes', create ticket to notify agent.  

	Used CPAN modules:
	
		use Time::Piece;
		use DateTime;
	

1. In this github, we will using *Hardware* class.  

2. Configure Config Item class to have date field and some marking field.  
For example in Hardware class, the date field (WarrantyExpirationDate) already defined by default:  

  		{  
        		Key => 'WarrantyExpirationDate',  
        		Name => Translatable('Warranty Expiration Date'),  
        		Searchable => 1,  
        		Input => {  
        	    		Type => 'Date',  
        	    		YearPeriodPast => 20,  
        	    		YearPeriodFuture => 10,  
        		},  
    		},  
		
Then, do add these additional parameter to get 'marking field'.  

	 	{  
	 		Key => 'RenewalAlert',  
	 		Name => Translatable('Renewal Alert'),  
	 		Searchable => 1,  
	 		Input => {  
	 		    Type => 'GeneralCatalog',  
	 		    Class => 'ITSM::ConfigItem::YesNo',  
	 		    Translation => 1,  
	 		    Required => 1,  
	 		},  
	 	},  


So our 2 key name here is **WarrantyExpirationDate** and **RenewalAlert**  


3. Enable and configure a new custom cron at System Configuration > Daemon::SchedulerCronTaskManager::Task###Custom1

Example:

	Function => Execute  
	MaximumParallelInstances => 1  
	Module => Kernel::System::Console::Command::Maint::ITSM::Configitem::CIExpiringDateV2  
	Params => 
	
	--queue
	Postmaster
	--ci-date-field
	WarrantyExpirationDate
	--ci-mark-field
	RenewalAlert
			
	Schedule => 0 9 * * 1  
	TaskName => Custom1

Where,  
--queue            #Specify the queue name where the reminder ticket should be create (default: Misc).  
--ci-date-field    #Specify the config item date field that determine expiring date. #E.g: WarrantyExpirationDate  
--ci-mark-field    #Specify the config item dropdown field that determine reminder should be create or not. #E.g: RenewalAlert  


4. Save then restart your Daemon. It will execute based on schedule value (Every week monday 9.00 am ).  

5. To manually execute cron or test via Console  

otrs@shell > bin/otrs.Console.pl Maint::ITSM::Configitem::CIExpiringDateV2 --queue Postmaster --ci-date-field WarrantyExpirationDate --ci-mark-field RenewalAlert

[![donload1.png](https://i.postimg.cc/QMK8WD7T/donload1.png)](https://postimg.cc/HJHDffBY)  

[![donlod2.png](https://i.postimg.cc/SsmPb7mx/donlod2.png)](https://postimg.cc/8Fn4hvF2)  

[![donlod3.png](https://i.postimg.cc/NMPkC1MV/donlod3.png)](https://postimg.cc/PpYDPv1z)  

