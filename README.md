# OTRS-Config-Item-Notification  
- Built for OTRS CE v 6.0.x  
- Check ITSM Config Item (CI) expiring date within current month or next 1/2/3 month , then change deployment state or create ticket to notify agent.  

Paypal: [![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://paypal.me/MohdAzfar?locale.x=en_US)   
  
1. Module Behaviour
	
	- Search for effected ci based on the parameter
	- Create a ticket
	- Link the ticket with ci
	- Set ci deployment state to something else
	
  	
2. Do run the command via the console first to see mandatory and optional parameter. 

		otrs@shell > bin/otrs.Console.pl Maint::ITSM::Configitem::CIExpiringDateV2
  
	WHERE,  
	--class ... (--class ...)      - Specify the config item class which this check should be perform. (Accept multiple class)  
	--depl-state ... (--depl-state ...) - Specify the config item deployment state which this check should be perform. (Accept multiple deployment state)  
	--date-field ...               - Specify the config item date field name that determine expiring date.  
	--check-period ...             - Specify the lookup range (from 0 to 3) in month. 0 = current month, 1 = next 1 month, 2 = next 2 month, 3 = next 3 month  
	--depl-state-after ...         - Specify the config item deployment state to be set after the check.  
	[--queue ...]                  - Ticket will be create in the mention queue if this parameter is being used  
  
    	
3. Enable and configure a new custom cron at System Configuration > Daemon::SchedulerCronTaskManager::Task###Custom1

Example:

	Function => Execute  
	MaximumParallelInstances => 1  
	Module => Kernel::System::Console::Command::Maint::ITSM::Configitem::CIExpiringDateV2  
	Params => 
	
	--class
	Computer						
	--date-field
	WarrantyExpirationDate
	--depl-state 
	Production					
	--depl-state-after 
	Review				
	--check-period 
	1						
	--queue 
	Raw				
			
	Schedule => 0 9 * * 1  
	TaskName => Custom1

4. Save then restart your Daemon. It will execute based on schedule value (Every week monday 9.00 am ).  

[![1.png](https://i.postimg.cc/ydxBrBzZ/1.png)](https://postimg.cc/yJMwkMx1)

[![2.png](https://i.postimg.cc/G9wC2yTF/2.png)](https://postimg.cc/FkZqC1Zz)

[![3.png](https://i.postimg.cc/xdTcYw20/3.png)](https://postimg.cc/YvZpzy0V)

