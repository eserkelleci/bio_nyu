#!/usr/local/bin/perl
#-------------------------------------------------------------------------#
#   This program reads an MGF file and converts it into the standard MGF file
#   format ##   
#-------------------------------------------------------------------------#

use strict;

my $error=0;
my $MGFFileName="";
my $dir="";
my $line="";
my $mz="";
my $intensity="";
my $time="";
my $charge="";
my $pepmass1="";
my $time_="";
my $charge_="";
my $pepmass1_="";
my $scan=0;
my $filenames="";

if ($ARGV[0]=~/\w/) { $MGFFileName=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $dir=$ARGV[1];} else { $dir="."; }
$filenames=$MGFFileName;
$filenames=~s/\.old\.mgf//;
if ($error==0)
{
	if(open (IN, qq!$MGFFileName!))
	{
		if(open (OUT,qq!>$filenames.mgf!))
		{
			while($line = <IN>)
			{
				if($line=~/BEGIN IONS/)
				{
					print OUT "$line";
					$scan++;
				} 								 
				if($line=~/RTINSECONDS=([0-9\.\-\+]+)/)
				{
					$time=$1;
					$time_=$time;
					print OUT "TITLE=Scan $scan, Time=$time_, MS2, CID\n";
					print OUT "PEPMASS=$pepmass1_\n";
					if($charge_=~/\w/) {	print OUT "CHARGE=$charge_\n"; $charge_="";}
					else { print OUT "CHARGE=0\n"; } 
				}
				if ($line=~/^PEPMASS=([0-9\.\-\+edED]+)$/)
				{
					$pepmass1=$1;
					$pepmass1_=$pepmass1;
				}										
				if ($line=~/^CHARGE=([0-9]+).*/)
				{
					$charge=$1;
					$charge_=$charge;
				}
				if ($line=~/^([0-9\.\+\-edED]+)\s([0-9\.\+\-edED]+)/)
				{
					$mz=$1;
					$intensity=$2;
					print OUT "$mz\t$intensity\n";
				}
				if($line=~/END IONS/)
				{
					print OUT "$line\n";
				}
				$time="";
				$pepmass1="";
				$charge="";
				$line="";
			}
			
		}
		close(OUT);	
	}
	else
	{
		print "Could not open \"$MGFFileName\".\n";
		$error=1;
	}
}
else
{
	print "Name of MGF file is missing\n";
}
close(IN);