#!/usr/local/bin/perl
#
require "./masses_and_fragments.pl";
use strict;

my $error=0;
my $filename="";
my $charge_min=1;
my $charge_max=4;

if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $filename="test"; }

my $line="";
my $count=0;

if ($error==0)
{
	if (open (IN,"$filename"))
	{
		if (open (OUT,">$filename.addedO.out"))
		{
			$line=<IN>;
			chomp($line);
			print OUT "$line\n";
			while ($line=<IN>)
			{
				chomp($line);
				if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t(.*)$/)
				{
					my $pep=$1;
					my $int1=$2;
					my $int2=$3;
					my $int3=$4;
					my $m=$5-1.007276;
					print OUT "$line\n";
					my $m_count = ( $pep=~tr/M/M/ );
					if ($m_count>0)
					{
						for(my $i=1;$i<=$m_count;$i++)
						{
							my $int1_=$int1*0.99762;
							my $int2_=$int2*0.99762+$int1*0.00038;
							my $int3_=$int3*0.99762+$int2*0.00038+$int1*0.00200;
							$int1="1.000000";
							$int2=int(1000000*$int2_/$int1_)/1000000;
							$int3=int(1000000*$int3_/$int1_)/1000000;
							print OUT qq!$pep+O$i\t$int1\t$int2\t$int3!;
							for(my $k=$charge_min;$k<=$charge_max;$k++)
							{
								my $mz = ($m + $i*15.99491463) / $k + 1.007276;
								for(my $l=1;$l<=3;$l++)
								{
									my $mz_=$mz+(($l-1)*(13.0033548-12.0))/$k;
									my $int=0;
									print OUT qq!\t$mz_!;
								}
							}
							print OUT qq!\n!;
						}
					}
				}
			}	
			close(OUT);
		}
		close(IN);
	}
}