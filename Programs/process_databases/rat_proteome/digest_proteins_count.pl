#!/usr/local/bin/perl
# This program accepts the rat ensemble fasta file and a directory with fasta files. It digests the rat ensembl fasta and produces
# tryptic peptides, then digests other input fasta files into tryptic peptides. Total tryptic peptide count for each protein (in input fasta files) and
# the count of tryptic peptides for each protein that matches with the tryptic peptides of rat ensembl are computed.

#require "./masses_and_fragments.pl";
use strict;

my $error=0;
my $dir="";
my $dbfile="";
my $resdir="";
my $incompletes=0;
my $filename=0;

if ($ARGV[0]=~/\w/) { $dbfile=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $dir=$ARGV[1];} else { $dir="."; }
if ($ARGV[2]=~/\w/) { $resdir=$ARGV[2];} else { $resdir="."; }
if ($ARGV[3]=~/\w/) { $incompletes=$ARGV[3];} else { $incompletes=0; }

my $total_pep_count=0;
my %PEP=();
my %PEP_proteins=();
my %PEP_proteins_count=();
my $files_count=0;
my $peptides_count=0;
my $proteins_count=0;
my %proteins_count={};
my $line="";
my %trypticpeptides=();

my $dbfile_=$dbfile;
$dbfile_=~s/^.*\/([^\/]+)$/$1/; 
my $dir_=$dir;
$dir_=~s/^.*\/([^\/]+)$/$1/;  

open(OUT1,">$resdir/$dbfile_\-$dir_\-count.txt");
print OUT1 qq!Protein name\tTotal peptide count\tOverlapped peptide count\n!;
if ($error==0)
{
	### digesting the rat ensembl fasta file ###
	if (open (IN,"$dbfile"))
	{
		#print qq!$filename\n!;
		my $name="";
		my $sequence="";
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~s/^>//)
			{
				my $name_=$line;
				if ($name_=~s/^\"//)
				{
					$name_=~s/\"$//;
					$name_=~s/[^\w]/_/g;
				}
				else
				{
					$name_=~s/\s.*$//;
				}
				if ($name=~/\w/ and $sequence=~/\w/)
				{
					$proteins_count++;
					$proteins_count{$filename}++;
					#print "$proteins_count. $name\n";
					%PEP=();
					DigestTrypsin($name,$sequence,$incompletes);
					foreach my $peptide (keys %PEP)
					{
						if (length($peptide)>6)
						{
							if ($PEP_proteins{$peptide}!~/#$name#/) 
							{
								$PEP_proteins_count{$peptide}++;
								$PEP_proteins{$peptide}.=qq!#$name#!;
							}
							$trypticpeptides{$peptide}=1;
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
			$proteins_count++;
			$proteins_count{$filename}++;
			#print "$proteins_count. $name\n";
			%PEP=();
			DigestTrypsin($name,$sequence,$incompletes);
			foreach my $peptide (keys %PEP)
			{
				#print qq!$peptide\n!;
				if (length($peptide)>6)
				{
					if ($PEP_proteins{$peptide}!~/#$name#/) 
					{
						$PEP_proteins_count{$peptide}++;
						$PEP_proteins{$peptide}.=qq!#$name#!;
					}
					$trypticpeptides{$peptide}=1;
				}
			}
		}
		close(IN);
		$files_count++;
		print qq!$files_count. $filename $proteins_count{$filename}\n!;
	}
	my $trypticpeptides_total_count=0;
	my $trypticpeptides_count=0;
	### digesting the fasta files in the input directory ####
	if (opendir(DIR,"$dir"))
	{
		my @allfiles=readdir DIR;
		closedir DIR;
		foreach my $filename (@allfiles)
		{
			if ($filename=~/\.fasta$/i)
			{
				if (open (IN,"$dir/$filename"))
				{
					#print qq!$filename\n!;
					my $name="";
					my $sequence="";
					while ($line=<IN>)
					{
						chomp($line);
						if ($line=~s/^>//)
						{
							my $name_=$line;
							if ($name_=~s/^\"//)
							{
								$name_=~s/\"$//;
								$name_=~s/[^\w]/_/g;
							}
							else
							{
								$name_=~s/\s.*$//;
							}
							if ($name=~/\w/ and $sequence=~/\w/)
							{
								$proteins_count++;
								$proteins_count{$filename}++;
								#print "$proteins_count. $name\n";
								%PEP=();
								DigestTrypsin($name,$sequence,$incompletes);
								foreach my $peptide (keys %PEP)
								{
									if (length($peptide)>6)
									{
										if ($PEP_proteins{$peptide}!~/#$name#/) 
										{
											$PEP_proteins_count{$peptide}++;
											$PEP_proteins{$peptide}.=qq!#$name#!;
										}
										$trypticpeptides_total_count++;
										if($trypticpeptides{$peptide}== 1){ $trypticpeptides_count++;}
									}
								}
								print OUT1 qq!$name\t$trypticpeptides_total_count\t$trypticpeptides_count\n!;
							}
							$name=$name_;
							$sequence="";
							$trypticpeptides_total_count=0;
							$trypticpeptides_count=0;
						}
						else
						{
							$sequence.="$line";
						}
					}	
					if ($name=~/\w/ and $sequence=~/\w/)
					{
						$proteins_count++;
						$proteins_count{$filename}++;
						#print "$proteins_count. $name\n";
						%PEP=();
						DigestTrypsin($name,$sequence,$incompletes);
						foreach my $peptide (keys %PEP)
						{
							#print qq!$peptide\n!;
							if (length($peptide)>6)
							{
								if ($PEP_proteins{$peptide}!~/#$name#/) 
								{
									$PEP_proteins_count{$peptide}++;
									$PEP_proteins{$peptide}.=qq!#$name#!;
								}
								$trypticpeptides_total_count++;
								if($trypticpeptides{$peptide}== 1){ $trypticpeptides_count++;}
							}
						}
						print OUT1 qq!$name\t$trypticpeptides_total_count\t$trypticpeptides_count\n!;
					}
					close(IN);
					$files_count++;
					print qq!$files_count. $filename $proteins_count{$filename}\n!;
				}
			}
		}
	} 
	if (open (OUT,">$resdir/$dir_\_predigested.fasta"))
	{
		foreach my $peptide (keys %PEP_proteins)
		{
			print OUT qq!>$peptide $PEP_proteins_count{$peptide}\n$peptide\n!;
		}
		close(OUT);
	}
}
close(OUT1);
sub DigestTrypsin
{
	my $name = shift();
	my $seq = shift();
	my $incompletes = shift();

	my $temp=$seq;
	my @pep=();
	my @start=();
	my @end=();
	my $aa="";
	my $aa_="";
	my $i=0;

	for($i=0;$i<=$incompletes;$i++)
	{
		$start[$i]=0;
		$end[$i]=-1;
		#$pep[$i]="[";
	}
	my $aa_count=0;
	while ($temp=~s/^\s*([A-Z\*])//)
	{
		$aa="\U$1";
		$aa=~s/I/L/g;
		if ( (($aa_=~/R/ or $aa_=~/K/) and $aa!~/P/) or $aa_=~/\*/)
		{
			for($i=0;$i<=$incompletes;$i++)
			{
				$PEP{"$pep[$i]"}=1;
				$pep[$i]=$pep[$i+1];
				$start[$i]=$start[$i+1];
				$end[$i]=$end[$i+1];
			}
			$start[$incompletes]=$aa_count;
			$end[$incompletes]=$aa_count-1;
		}
		for($i=0;$i<=$incompletes;$i++)
		{
			if ($aa!~/\*/) { $pep[$i].=$aa; }
			$end[$i]++;
		}
		$aa_=$aa;
		$aa_count++;
	}
	for($i=0;$i<=$incompletes;$i++)
	{
		$PEP{"$pep[$i]"}=1;
	}
}
