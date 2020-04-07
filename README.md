# OTRS-Config-Item-Notification
- Work In Progress ...
- Built for OTRS v6.0.x CE
- Check Config Item expiring date and if within current month, create ticket to notify agent.

1. Create a new custom cron.  

Example:  

Admin > System Configuration > Daemon::SchedulerCronTaskManager::Task###Custom1 

	Function => Execute  
	Module => Kernel::System::Console::Command::Maint::ITSM::Configitem::CIExpiringDate  
	Schedule => 0 9 * * 1  
	TaskName => Custom1  
	
3. To manually execute cron via Console  

	otrs@shell > /opt/otrs/bin/otrs.Console.pl Maint::ITSM::Configitem::CIExpiringDate  
