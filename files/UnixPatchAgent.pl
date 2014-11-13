#!/usr/bin/perl
use strict;
#==============================================================================
# Lemms patch agent - UBC customized installation script
#
# Run this script to install the LEMMS patch agent and register it with the
# LEMMS server.
#
# You can provide the LEMMS group name to assign the server to as the "-group <name>"
# argument - if not provided you are prompted for the group name.
#
# NOTE:  This script installs a SUN Java JRE specifically for use by the LEMMS agent.
#==============================================================================
#select(stdout); $| = 1;		# Turn off output buffering

# Global Variables
my $tmp_dir       = '/tmp/patchagent';
my $src_dir       = 'http://patch.it.ubc.ca/download';
my $tgt_dir	  = '/usr/local/patchagent';
my $agent_file    = 'UnixPatchAgent.tar';
my $jre_version   = 'jre1.6.0_34';
my $jre_32_file   = 'jre-6u34-linux-i586.bin';
my $jre_64_file   = 'jre-6u34-linux-x64.bin';
my $agent_cksum   = 'c0b74843c31697b0be17eafc48bd37c9';
my $jre_32_cksum  = '0040e2404f0dd2a2d6e8df64798f1fc0';
my $jre_64_cksum  = 'd5d23e93a8bcc391e764857ddacc3ea5';
my $logfile       = "$tgt_dir/install.log";
my $install_args  = "-silent -d /usr/local -p https://patch.it.ubc.ca -sno FC39CF41-B91D74A8";
my $patch_group   = '';
my $patch_group   = join('|',@ARGV);   # Arguments are groups to join server to.

my $err = '';

my $e_status = mkdir("/tmp/aaaa");
print $e_status."\n";
system("ls") && die "Failed ${^TAINT}, ${^CHILD_ERROR_NATIVE}";

eval {

   # Ensure the script is running as root - exit immediately if not
   exit 0 if $> != 0 && print("Script must be run as root\n");

   # See if patch agent is already installed - exit mmediately if not
   exit 0 if -d "$tgt_dir" && print("Target directory '$tgt_dir' already exists - is agent already installed?\n");

   # Ensure this is a redhat linux system and extract bits.
   die("Unable to determine redhat release - this script is only supported on RHEL systems\n") unless -r '/etc/redhat-release';
   my $release = `/bin/cat /etc/redhat-release`;
   chomp($release);
   my $proc = `/bin/uname -p`;
   my $bits = 32;
   $bits = 64 if $proc =~ m/^(x86_64)$/;
   print "Redhat Release: $release - $bits bit\n";

   # Prompt for group to join if not provided as an argument
   unless ( $patch_group ) {
      print(STDERR "Please enter the group to register this patch agent in (empty for default)\n");
      print(STDERR "Group:");
      $patch_group = <STDIN>;
      chomp($patch_group);
   }
   $install_args .= " -g '$patch_group'" if $patch_group;
  
   # Create temp directory for fetching files into - delete any existing one first.
   #system("rm -rf $tmp_dir > /dev/null 2>&1");
   #system("mkdir $tmp_dir > /dev/null 2>&1") && die "Failure creating temporary working directory: $tmp_dir";

   # Download, install, and test the JRE
   print "Downloading JRE...\n";
   my $jre_file = $jre_32_file;
   my $jre_cksum = $jre_32_cksum;
   if ( $bits == 64 ) {
      $jre_file = $jre_64_file;
      $jre_cksum = $jre_64_cksum;
   }
   fetch("$src_dir/$jre_file", $jre_cksum);

   print "Installing JRE...\n";
   system("mkdir -p $tgt_dir > /dev/null 2>&1") && die "Failure creating directory: $tgt_dir";
   system("(chmod a+rx $tmp_dir/$jre_file; cd $tgt_dir; $tmp_dir/$jre_file) > /dev/null 2>&1") && die 'Failure installing JRE';

   print "Testing JRE...\n";
   $ENV{'PATCHAGENT_JRE'} = "$tgt_dir/$jre_version";
   $ENV{'JAVA_HOME'} = "$tgt_dir/$jre_version";
   $ENV{'CLASSPATH'} = "$tgt_dir/$jre_version/lib:$ENV{'CLASSPATH'}";
   $ENV{'PATH'} = "$tgt_dir/$jre_version/bin:$ENV{'PATH'}";
   system('java -version') && die 'Failure determining JRE version';

   # Download and install the patch agent
   print "Downloading Patch Agent...\n";
   fetch("$src_dir/$agent_file", $agent_cksum);

   print "Extracting Patch Agent...\n";
   system("(cd $tmp_dir;tar -xf $agent_file) > /dev/null 2>&1") && die 'Failure extracting patch agent';
   print "Installing Patch Agent...\n";
   system("(cd $tmp_dir; ./install $install_args) > $logfile  2>&1") && die 'Failure installing patch agent';

   # Update the selinux context to allow patching with selinux active - wait for file to exist
   print "Updating Patch Agent Selinux context...";
   while ( ! -e "$tgt_dir/mcescan/bin/python" ) {
      sleep 1;
      print '.';
   }
   print "\n";

   # Skip setting contexts if selinux is disabled - it will fail...
   my $selinuxmode = `/usr/sbin/getenforce`;
   if ( $selinuxmode !~ /^Disabled/ ) {
      system("chcon -t rpm_exec_t $tgt_dir/mcescan/bin/python") && die 'Failure updating patchagent selinux context';
   }

   print "Patch Agent Installation successfull. Dump of install log follows:\n";
   system("cat $logfile");

   # Issue a warning if selinux is in disabled or permissive state. Most secure if enabled!
   if ( $selinuxmode =~ /^Permissive/ ) {
      print "\n\nWARNING: selinux is in permissive mode!\n";
   } elsif ($selinuxmode =~ /^Disabled/ ) {
      print "\n\nWARNING: selinux is disabled!\n";
   }
};
$err = $@ if $@;

# Cleanup  - on success or failure!
system("rm -rf $tmp_dir");

# Dump logfile if it exists and we had an error
if ( $err && -e $logfile ) {
    print "Error encountered - dumping logfile $logfile:\n";
    system("cat $logfile");
}

# Die with information message if there was an error
die "\n\nScript Failure: $err\n" if $err;

exit 0;



#------------------------------------------------------------------------------
# Fetch a file from a URL - validate it's md5 checksum
#   1 - URL to fetch
#   2 - Expected MD5 sum of file
#  
# All files are retrieved into the $tmp_dir directory
#------------------------------------------------------------------------------
sub fetch {
   my($url, $md5sum) = @_;
   our($wget);
   
   # The first time this subroutine is called we test which wget options are
   # supported and determine the command to use to retrieve web content.
   if ( !defined($wget) ) {
      die('/usr/bin/wget not found') unless -e '/usr/bin/wget'; 
      die('/usr/bin/wget not executable') unless -x '/usr/bin/wget';
      $wget = '/usr/bin/wget -q';
      my $output = `LANG=en_US /usr/bin/wget --no-check-certificate 2>&1`;
      $wget .=  $output =~ m/unrecognized option/gi ? '' : ' --no-check-certificate';
   }
   
   # Extract the file name from the last level of the URL.
   $url =~ m|.*/(.*)$|;
   my $file = "$tmp_dir/$1";

   # Fetch the file
   system("$wget -O $file $url");
   die("Failure fetching '$url'\n") unless -e $file;

   # Extract and compare the MD5 checksums
   my $md5data = `/usr/bin/md5sum $file`;
   $md5data =~ m/^(\S+)/;
   my $md5 = $1;
   die("Checksum failure for url '$url': checksum=$md5 expected=$md5sum\n") unless $md5 eq $md5sum;
}
