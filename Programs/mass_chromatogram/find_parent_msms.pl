#!/usr/local/bin/perl
#
sub numerically { $a <=> $b; }

$Rlocation="C:\\R\\bin\\x64\\Rterm.exe";
$this_location="D:/Programs/mass_chromatogram";
$this_location_="D:\\Programs\\mass_chromatogram";
$error=0;

if ($ARGV[0]=~/\w/) { $mgffilename=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $peptidelistname=$ARGV[1];} else { $error=1; }
if ($ARGV[2]=~/\w/) { $mass_error=$ARGV[2];} else { $mass_error=10; }

$mgffilename=~s/\\/\//g;
$peptidelistname=~s/\\/\//g;
$peptidelistname_=$peptidelistname;
$peptidelistname_=~s/^.*\/([^\/]+)$/$1/;
$dir=$mgffilename;
$dir=~s/\.mgf$//i;
$dir=~s/\.MS2\..*$//i;
$dir=~s/\.mzXML$//i;
$dir.=".mzXML-$peptidelistname_.dir";
print qq!$dir\n!;
mkdir($dir);
$result="$dir/$mgffilename-$peptidelistname_.scans.txt";

if ($error==0)
{
	if (open(IN,"$peptidelistname"))
	{
		print qq!$peptidelistname\n!;
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t/)
			{
				$pep[$pep_count]=$1;
				$mod[$pep_count]=$2;
				$charge[$pep_count]=$3;
				$mz[$pep_count]=$4;
				$peak_num[$pep_count]=$6;
				if (0<$peak_num[$pep_count])
				{
					$mz_int=int($mz[$pep_count]);
					$index{$mz_int}.="#$pep_count#";
					$index{$mz_int+1}.="#$pep_count#";
					$index{$mz_int-1}.="#$pep_count#";
					#$mod[$pep_count]=~s/^[0-9]+$//;
					$pep_count++;
				}
			}
		}
		close(IN);
		#foreach $index (sort {$a<=>$b} keys %index)
		#{
		#	print qq!$index: $index{$index}\n!;
		#}
		
		if (open (IN, "$mgffilename"))
		{
			my $charge=0;
			my $scan=0;
			my $title="";
			my $line="";
			my $pepmass=0;
			print qq!$mgffilename\n!;
			while($line=<IN>)
			{	
				if($line=~/BEGIN IONS/)
				{
					$charge=0;
					$scan=0;
					$title="";
					$pepmass=0;
				}
				if ($line=~/^TITLE=(.*)$/)
				{
					$title=$1;
				}
				if($line=~/Scan\s+([0-9]+)/)
				{
					$scan=$1;
				}
				if ($line=~/^PEPMASS=([0-9\.\-\+edED]+)\s?([0-9\.\-\+edED]*)\s*$/)
				{
					$pepmass=$1;
				}
				
				if ($line=~/^CHARGE=([0-9\.\-\+]+)\s*$/)
				{
					$charge=$1;
				}
					
				if($line=~/END IONS/)
				{
					if ($pepmass=~/\w/)
					{
						$mz_int=int($pepmass);
						$found=1;
						$temp=$index{$mz_int};
						while($temp=~s/#([^#]+)#//)
						{
							$index=$1;
							if (abs($mz[$index]-$pepmass)/$pepmass*1e+6<=$mass_error and $charge[$index]==$charge)
							{
								$info{"$pep[$index]_$mod[$index]"}.=qq!$pep[$index]\t$mod[$index]\t$charge[$index]\t$peak_num[$index]\t$mz[$index]\t$pepmass\t$charge\t$scan\n!;
								$info_{"$pep[$index]_$mod[$index]"}.=qq!$charge[$index]\t$scan\n!;
							}
						}
					}
				}	
			}
			close(IN);
		}
		
		if (open (OUT, ">$result"))
		{
			print OUT qq!pep\tmod\tcharge\tpeak_num\tmz\tmgf_mz\tmgf_charge\tmgf_scan\n!;
			foreach $pep_mod (sort keys %info)
			{
				if ($pep_mod=~/\w/)
				{
					print OUT $info{$pep_mod};
					if (open (OUT_, ">$dir/$pep_mod.scans.txt"))
					{
						print OUT_ qq!charge\tmgf_scan\n!;
						print OUT_ $info_{$pep_mod};
						close(OUT_);
					}
				}
			}
			close(OUT);
		}
	}
}
