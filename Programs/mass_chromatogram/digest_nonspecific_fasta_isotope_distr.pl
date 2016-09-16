#!/usr/local/bin/perl
#
require "./masses_and_fragments.pl";
use strict;

my $error=0;
my $filename="";
my $length_min=0;
my $length_max=0;
my $charge_min=0;
my $charge_max=0;

if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $filename="test"; }
if ($ARGV[1]=~/\w/) { $length_min=$ARGV[1];} else { $length_min=7; }
if ($ARGV[2]=~/\w/) { $length_max=$ARGV[2];} else { $length_max=27; }
if ($ARGV[3]=~/\w/) { $charge_min=$ARGV[3];} else { $charge_min=1; }
if ($ARGV[4]=~/\w/) { $charge_max=$ARGV[4];} else { $charge_max=4; }

my $line="";
my $count=0;

if ($error==0)
{
	if (open (IN,"$filename"))
	{
		if (open (OUT,">$filename.out"))
		{
			print OUT qq!peptide!;
			for(my $l=1;$l<=3;$l++)
			{
				print OUT qq!\trelative intensity (isotope peak $l)!;
			}
			for(my $k=$charge_min;$k<=$charge_max;$k++)
			{
				for(my $l=1;$l<=3;$l++)
				{
					print OUT qq!\tm/z (charge = $k, isotope peak $l)!;
				}
			}
			print OUT qq!\n!;
			my $name="";
			my $sequence="";
			while ($line=<IN>)
			{
				chomp($line);
				if ($line=~s/^>//)
				{
					my $name_=$line;
					if ($name=~/\w/ and $sequence=~/\w/)
					{
						print "$name\n";
						for(my $i=$length_min;$i<=$length_max;$i++)
						{
							for(my $j=0;$j<=length($sequence)-$i;$j++)
							{
								my $seq = substr $sequence,$j,$i;
								print OUT qq!$seq!;
								print "$count\n";
								$count++;
								if (open(OUT_TEMP,">digest_nonspecific_fasta_isotope_distr.temp"))
								{
									print OUT_TEMP qq!$seq\n!;
									close(OUT_TEMP);
									system(qq!isotope.exe digest_nonspecific_fasta_isotope_distr.temp 10000000!);
									system(qq!del digest_nonspecific_fasta_isotope_distr.temp!);
									if (open(IN_TEMP,"digest_nonspecific_fasta_isotope_distr.temp-isotope.txt"))
									{
										my $found=0;
										while($line=<IN_TEMP>)
										{
											if ($line=~/^$seq\tNew\t([0-9\.\-\+edED]+)\t([0-9\.\-\+edED]+)\t([0-9\.\-\+edED]+)/)
											{
												print OUT qq!\t$1\t$2\t$3!;
												$found=1;
											}
										}
										if ($found==0) { print OUT qq!\t\t\t!; }
										close(IN_TEMP);
										system(qq!del digest_nonspecific_fasta_isotope_distr.temp-isotope.txt!);
									} else { print OUT qq!\t\t\t!; }
								} else { print OUT qq!\t\t\t!; }
								for(my $k=$charge_min;$k<=$charge_max;$k++)
								{
									my $mz=Pepmz($seq,$k);
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
					$name=$name_;
					$sequence="";
				}
				else
				{
					$sequence.="$line";
				}
			}
					
					
					
					if ($name=~/\w/ and $sequence=~/\w/)
					{
						print "$name\n";
						for(my $i=$length_min;$i<=$length_max;$i++)
						{
							for(my $j=0;$j<=length($sequence)-$i;$j++)
							{
								my $seq = substr $sequence,$j,$i;
								print OUT qq!$seq!;
								print "$count\n";
								$count++;
								if (open(OUT_TEMP,">digest_nonspecific_fasta_isotope_distr.temp"))
								{
									print OUT_TEMP qq!$seq\n!;
									close(OUT_TEMP);
									system(qq!isotope.exe digest_nonspecific_fasta_isotope_distr.temp 10000000!);
									system(qq!del digest_nonspecific_fasta_isotope_distr.temp!);
									if (open(IN_TEMP,"digest_nonspecific_fasta_isotope_distr.temp-isotope.txt"))
									{
										my $found=0;
										while($line=<IN_TEMP>)
										{
											if ($line=~/^$seq\tNew\t([0-9\.\-\+edED]+)\t([0-9\.\-\+edED]+)\t([0-9\.\-\+edED]+)/)
											{
												print OUT qq!\t$1\t$2\t$3!;
												$found=1;
											}
										}
										if ($found==0) { print OUT qq!\t\t\t!; }
										close(IN_TEMP);
										system(qq!del digest_nonspecific_fasta_isotope_distr.temp-isotope.txt!);
									} else { print OUT qq!\t\t\t!; }
								} else { print OUT qq!\t\t\t!; }
								for(my $k=$charge_min;$k<=$charge_max;$k++)
								{
									my $mz=Pepmz($seq,$k);
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
					
					
			close(OUT);
		}
		close(IN);
	}
}