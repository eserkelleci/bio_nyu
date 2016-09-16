#!c:/perl/bin/perl.exe
#
use File::Copy;

my %SETTINGS=(); open(IN,"../settings.txt"); while($line=<IN>) { chomp($line); if ($line=~/^([^\=]+)\=([^\=]+)$/) { $SETTINGS{$1}=$2; } } close(IN);
if ($ARGV[0]=~/\w/) { $continue="$ARGV[0]"; } else { $continue=""; }
$done=0;
my $result_folder="";
while($done==0)
{
	$date=GetDateTime();
	if (open(logfile,"demon.status"))
	{
		close(logfile);
		open(logfile,">>demon.log");
		print logfile "Previous still running $date\n";
		print "Previous still running $date\n";
		close(logfile);
	}
	else
	{
		if (open(logfile,">demon.status"))
		{
			close(logfile);
			open(logfile,">>demon.log");
			print logfile "STARTED $date\n";
			print "STARTED $date\n";
			close(logfile);
			my $found_files=1;
			while($found_files==1)
			{
				my @files=();
				my $count=0;
				system(qq!dir "$SETTINGS{'TASKS'}/todo" > psftp_temp.$ip.log !);
				if (open(IN,"psftp_temp.$ip.log"))
				{
					while($line=<IN>)
					{
						chomp($line);
						if ($line=~/(\S+\.xml)$/i)
						{
							$files[$count++]=$1;
						}
					}
					close(IN);
				}	
				system(qq!del psftp_temp.$ip.log!);
	
				open(logfile,">>demon.log");
				$date__=GetDateTime();
				print logfile "Found $count files $date__ ($SETTINGS{'TASKS'})\n";
				print "Found $count files $date__ ($SETTINGS{'TASKS'})\n";
				close(logfile);
				if ($count>0)
				{
					$found_files=1;
					$i=int(rand($count));
					$filename=$files[$i];
					open(IN,qq!$SETTINGS{'TASKS'}/todo/$filename!) || die "file missing $SETTINGS{'TASKS'}/todo/$filename"; 
					while($line=<IN>)
					{ 
						if($line=~/<experiment file="(.*)\/([^\/]+)"\/>/)
						{
							my $dir=$1; 
							if($dir=~/$SETTINGS{'DATA'}(.*)$/) { $pathname = $1; }
						}
					}
					close(IN);
					if(open(IN,qq!$SETTINGS{'TASKS'}/running/$SETTINGS{'DEMON'}/$filename!))
					{
						system(qq!del "$SETTINGS{'TASKS'}/running/$SETTINGS{'DEMON'}/$filename"!);
					}
					move("$SETTINGS{'TASKS'}/todo/$filename","$SETTINGS{'TASKS'}/running/$SETTINGS{'DEMON'}");
					# move("$SETTINGS{'DATA'}$pathname/todo/$SETTINGS{'DEMON'}/$filename","$SETTINGS{'DATA'}$pathname/running/$SETTINGS{'DEMON'}");
					move("$SETTINGS{'DATA'}$pathname/todo/$filename","$SETTINGS{'DATA'}$pathname/running/$SETTINGS{'DEMON'}"); 
					$found=0; 
					if (open(IN,"$SETTINGS{'DATA'}$pathname/running/$SETTINGS{'DEMON'}/$filename"))
					{
						$found=1;
						close(IN);
					}
					if ($found==1)
					{
						$result_folder="$SETTINGS{'RESULT'}".$pathname; 
						open(logfile,">>demon.log");
						$date__=GetDateTime();
						my $date_=GetDateTime_();
						print logfile "$filename $date__\n";
						close(logfile);
						if($filename=~/^(.*)\_\_(.*)$/) { $project_name= $1; } 
						system(qq!pipeline.pl $SETTINGS{'DATA'}$pathname/running/$SETTINGS{'DEMON'}/$filename $date_ $project_name $result_folder >> pipeline.log!);  ### code change
						#move("$SETTINGS{'TASKS'}/running/$SETTINGS{'DEMON'}/$filename","$SETTINGS{'TASKS'}/done/$SETTINGS{'DEMON'}/$filename-$date_");
						move("$SETTINGS{'TASKS'}/running/$SETTINGS{'DEMON'}/$filename","$SETTINGS{'TASKS'}/done/$filename-$date_");
						#move("$SETTINGS{'DATA'}$pathname/running/$SETTINGS{'DEMON'}/$filename","$SETTINGS{'DATA'}$pathname/done/$SETTINGS{'DEMON'}/$filename-$project_name-$date_");
						move("$SETTINGS{'DATA'}$pathname/running/$SETTINGS{'DEMON'}/$filename","$SETTINGS{'DATA'}$pathname/done/$filename-$project_name-$date_");
					}
				} else { $found_files=0; $pathname = ""; }
			}
			$date_=GetDateTime();
			open(logfile,">>demon.log");
			print logfile "DONE $date_ (started $date)\n";
			print "DONE $date_ (started $date)\n";
			close logfile;
			system("del demon.status");
		}
	}
	if ($continue=~/\w/) { print qq!Sleeping\n!; sleep(300); } else { $done=1; }
}

sub GetDateTime
{
	my $sec="";
	my $min="";
	my $hour="";
	my $mday="";
	my $mon="";
	my $year="";

	($sec,$min,$hour,$mday,$mon,$year) = localtime();

	if ($sec<10) { $sec="0$sec"; }
	if ($min<10) { $min="0$min"; }
	if ($hour<10) { $hour="0$hour"; }
	if ($mday<10) { $mday="0$mday"; }
	$mon++;
	if ($mon<10) { $mon="0$mon"; }
	$year+=1900;
	$date="$year-$mon-$mday $hour:$min:$sec";
	
	return $date;
}

sub GetDateTime_
{
	my $sec="";
	my $min="";
	my $hour="";
	my $mday="";
	my $mon="";
	my $year="";

	($sec,$min,$hour,$mday,$mon,$year) = localtime();

	if ($sec<10) { $sec="0$sec"; }
	if ($min<10) { $min="0$min"; }
	if ($hour<10) { $hour="0$hour"; }
	if ($mday<10) { $mday="0$mday"; }
	$mon++;
	if ($mon<10) { $mon="0$mon"; }
	$year+=1900;
	$date="$year-$mon-$mday-$hour-$min-$sec";
	
	return $date;
}
