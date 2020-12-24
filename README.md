# OTRS-Config-Item-Notification  
- Built for OTRS CE v 6.0.x  
- Check Config Item (ci) expiring date and if within current month and next 1/2/3 month , create ticket to notify agent.  

1. Module Behaviour
	
	- Search for effected ci based on the parameter
	- Create a ticket
	- Link the ticket with ci
	- Set ci deployment state to something else
	
  	
2. For debug purpose, you may run the command via the console first.

		otrs@shell > bin/otrs.Console.pl Maint::ITSM::Configitem::CIExpiringDateV2

Example: 

		otrs@shell > bin/otrs.Console.pl Maint::ITSM::Configitem::CIExpiringDateV2 --class Computer --class Hardware --date-field WarrantyExpirationDate --depl-state Production --depl-state Planned --depl-state-after Review --check-period 1 --queue Raw 

		WHERE,
			--class Computer						#search for ci in mention class
			--date-field WarrantyExpirationDate 	#ci date field name that hold expiring date value
			--depl-state Production					#also search for ci in specific deployment state
			--depl-state-after Review				#specify the ci deployment state to be set after the check.
			--check-period 1						#specify the lookup range (from 1 to 3) in month.
			--queue Raw								#Optional. Specify the queue name where the reminder ticket should be create.
	
	
3. Enable and configure a new custom cron at System Configuration > Daemon::SchedulerCronTaskManager::Task###Custom1

Example:

	Function => Execute  
	MaximumParallelInstances => 1  
	Module => Kernel::System::Console::Command::Maint::ITSM::Configitem::CIExpiringDateV2  
	Params => 
	
	--class Computer						
	--date-field WarrantyExpirationDate 	
	--depl-state Production					
	--depl-state-after Review				
	--check-period 1						
	--queue Raw				
			
	Schedule => 0 9 * * 1  
	TaskName => Custom1

4. Save then restart your Daemon. It will execute based on schedule value (Every week monday 9.00 am ).  

[![1.png](https://i.postimg.cc/ydxBrBzZ/1.png)](https://postimg.cc/yJMwkMx1)

[![2.png](https://i.postimg.cc/G9wC2yTF/2.png)](https://postimg.cc/FkZqC1Zz)

[![3.png](https://i.postimg.cc/xdTcYw20/3.png)](https://postimg.cc/YvZpzy0V)

