###################################################################################################
#
# Author: 			Tamas Bogdan <tamas.bogdan@hp.com>
# Maintainer:		Tamas Bogdan <tamas.bogdan@hp.com>
# Version: 			1.0 - 2014. january 14
# Description:		This script is emulates physical cable pull on Cisco switches
#
###################################################################################################

use strict;
use Net::Telnet::Cisco;

my $user = "";					# username
my $pass = "";					# password
my $ip = "";					# host or IP
my @port = ("9/9","9/11","9/10");		# ports to manipulate, NOTE: the first two ports will be used
my $elementSize = 0+@port;			# size of @port array
my $ntimes = 5;						# number of loops of cable pull cycles.. 1 cycle => all ports cable pull
my $sleeptime = 45;					# global sleep time

my $session = Net::Telnet::Cisco->new(
									Host => $ip, 
									Prompt  => '/colosseus.*\#/',	# without this you'll get command timed-out messages
									Timeout=>10,
									Input_log => "session.log");


$session->always_waitfor_prompt;	
$session->send_wakeup('connect');	# better to do that

$session->waitfor('/login:.*$/');
$session->print($user);
$session->waitfor('/Password:.*$/');
$session->print($pass);

print "Greetings, you are now logged in to $ip!\n";

sub bringAllPortsUp(){						# brings up all ports defined in @port
	$session->cmd("configure terminal");
	for (my $ii=0; $ii<$elementSize; $ii++){
		$session->cmd("interface fc $port[$ii]");
		$session->cmd("no shutdown");
		$session->cmd("exit");
		print "ifup $port[$ii]: done.\n";
	}
	print "waiting for $sleeptime sec before cable pulling..\n";
	sleep $sleeptime;
}

sub rotate(){
	for (my $i=1; $i<=$ntimes; $i++){							# n times looping
		for (my $j=0; $j<$elementSize-1; $j++){					# this is the effective loop of cable pulling..
			$session->cmd("interface fc $port[$j]");
			$session->cmd("shutdown");
			print "ifdown $port[$j] && sleep $sleeptime\n";
			sleep $sleeptime;
			$session->cmd("no shutdown");
			$session->cmd("exit");
			print "ifup $port[$j] && sleep $sleeptime\n";
			sleep $sleeptime;
			}
		}
	$session->cmd("exit");					# let's quit from the switch..
	$session->cmd("exit");					# and again to log out
	$session->close;						# close session

}	

bringAllPortsUp();
rotate();

