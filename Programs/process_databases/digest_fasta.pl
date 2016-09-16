#!/usr/local/bin/perl
#
#require "./masses_and_fragments.pl";
use strict;

my $error=0;
my $dir="";
my $incompletes=0;
my $good="";

if ($ARGV[0]=~/\w/) { $dir=$ARGV[0];} else { $dir="test"; }
if ($ARGV[1]=~/\w/) { $incompletes=$ARGV[1];} else { $incompletes=0; }
if ($ARGV[2]=~/\w/) { $good=$ARGV[2];} else { $good=""; }

my $total_pep_count=0;
my %PEP=();
my %PEP_proteins=();
my %PEP_proteins_count=();
my %PEP_proteins_good=();
my $files_count=0;
my $peptides_count=0;
my $proteins_count=0;
my %proteins_count={};
my $line="";

if ($error==0)
{
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
											if (!($good=~/\w/ and $name=~/$good/)) { $PEP_proteins_good{$peptide}="N"; }
										}
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
							if (length($peptide)>6)
							{
								if ($PEP_proteins{$peptide}!~/#$name#/) 
								{
									$PEP_proteins_count{$peptide}++;
									$PEP_proteins{$peptide}.=qq!#$name#!;
									if (!($good=~/\w/ and $name=~/$good/)) { $PEP_proteins_good{$peptide}="N"; }
								}
							}
						}
					}
					close(IN);
					$files_count++;
					print qq!$files_count. $filename $proteins_count{$filename}\n!;
				}
			}
		}
	}
	if (open (OUT,">$dir-peptides.fasta"))
	{
		foreach my $peptide (keys %PEP_proteins)
		{
			if ($PEP_proteins_good{$peptide}=~/N/ and $good=~/\w/)
			{
			}
			else
			{
				if (length($peptide)<10)
				{
					print OUT qq!>pep_$peptide\n$peptide\n!;
				}
				else
				{
					my $pep1 = substr $peptide,0,5;
					my $pep2 = substr $peptide,-5;
					print OUT qq!>pep_$pep1\_$pep2\n$peptide\n!;
				}
			}
		}
		close(OUT);
	}
	if (open (OUT,">$dir-peptides.txt"))
	{
		foreach my $peptide (keys %PEP_proteins)
		{
			if ($PEP_proteins_good{$peptide}=~/N/ and $good=~/\w/)
			{
			}
			else
			{
				print OUT qq!$peptide\n!;
			}
		}
		close(OUT);
	}
	if (open (OUT,">$dir-peptides.log"))
	{
		print OUT qq!Type\tpeptide\tnumber_of_proteins\tproteins\n!;
		foreach my $peptide (keys %PEP_proteins)
		{
			if ($PEP_proteins_good{$peptide}=~/N/ and $good=~/\w/)
			{
				print OUT qq!\t!;
			}
			else
			{
				print OUT qq!$good\t!;
			}
			print OUT qq!$peptide\t$PEP_proteins_count{$peptide}\t$PEP_proteins{$peptide}\n!;
			$peptides_count++;
		}
		close(OUT);
	}
}

print qq!$files_count, $proteins_count proteins, $peptides_count peptides!;


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
	while ($temp=~s/^\s*([A-Z])//)
	{
		$aa="\U$1";
		$aa=~s/I/L/g;
		if ( ($aa_=~/R/ or $aa_=~/K/) and $aa!~/P/)
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
			$pep[$i].=$aa;
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
