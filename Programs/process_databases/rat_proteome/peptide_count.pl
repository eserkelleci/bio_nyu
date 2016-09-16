#!c:/perl/bin/perl.exe
# This program determines the peptides sequences and 
# the count of such sequences present in
# mouse and rodent but not in rat
#
use strict;

my $error=0;
my $dir0="";
my $dir1="";
my $dir2="";
my $filename="";
my $line="";
my %peptides=();
my %protein_peptides=();
my %protein_sequences=();
my $protein_name="";
my %protein_desc=();
my $sequence=""; 
my $id=""; 
my $expect=0;
my $pep="";
if ($ARGV[0]=~/\w/) { $dir0=$ARGV[0];} else { $error=1; } 
if ($ARGV[1]=~/\w/) { $dir1=$ARGV[1];} else { $error=1; } 
if ($ARGV[2]=~/\w/) { $dir2=$ARGV[2];} else { $error=1; } 

if ($error==0)
{  
	if (opendir(dir,"$dir0"))
	{
		my @allfolders=readdir dir;
		closedir dir;
		foreach my $file (@allfolders)
		{
			if ($file!~/\.fasta$/i and $file!~/([\.]+)/i)
			{
				my $rat_folder=$file;
				opendir(dir,"$rat_folder");
				my @allfiles=readdir dir;
				closedir dir;
				foreach $filename (@allfiles)
				{
					if ($filename=~/\.xml$/i)
					{
						#print qq!$filename\n!;
						open (IN,qq!$dir0/$rat_folder/$filename!) || die "Could not open $filename\n";
						while ($line=<IN>)
						{
							if ($line=~/^\<protein\s+.*label="([^\"]+)"/)
							{
								$protein_name=$1;
							}
							if ($line=~/^\<\/protein\>/)
							{
								$protein_name="";
							}
							if ($line=~/^\<\/domain\>/)
							{
								$expect=0;
								$pep="";
								$id="";
							}
							if ($line=~/^\<domain\s+id="([0-9\.edED\+\-]+)".*expect="([0-9\.edED\+\-]+)".*seq="([A-Za-z]+)"/)
							{
								$id=$1;
								$expect=$2;
								$pep=$3;
								$pep=~tr/I/L/; 
								# if ($expect < 1e-2)
								# {
									$peptides{"$pep"}=1;
								# }
							}
						}
						close(IN);
					}
				}
			}
		}
	}
	my $count=0;
	if (opendir(dir,"$dir1"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		foreach $filename (@allfiles)
		{
			if ($filename=~/\.xml$/i)
			{
				print qq!$filename\n!;
				open (IN,qq!$dir1/$filename!) || die "Could not open $filename\n";
				while ($line=<IN>)
				{
					if ($line=~/^\<protein\s+.*label="([^\"\s]+)\s*([^\"]*)"/)
					{
						$protein_name=$1;
						$protein_desc{$protein_name}=$2;
					}
					if ($protein_name=~/\w/)
					{
						if ($line=~/^\<note label="description">([^\s]+)\s*(.*)\<\/note\>\s*/)
						{
							$protein_name=$1;
							$protein_desc{$protein_name}=$2;
						}
					}
					if($line=~/^([A-Z\s]+)/)
					{
						$line=~s/\s//g;
						$line=~s/\n//g;
						$line=~tr/I/L/;
						$sequence.=$line; 
					}
					if($line=~/^\<\/peptide\>/)
					{
						$protein_sequences{$protein_name}=$sequence; 
						$sequence="";
					}
					if ($line=~/^\<\/protein\>/)
					{
						$protein_name="";
					}
					if ($line=~/^\<\/domain\>/)
					{
						$expect=0;
						$pep="";
						$id="";
					}
					if ($line=~/^\<domain\s+id="([0-9\.edED\+\-]+)".*expect="([0-9\.edED\+\-]+)".*seq="([A-Za-z]+)"/)
					{
						$id=$1;
						$expect=$2;
						$pep=$3;
						$pep=~tr/I/L/;
						if ($expect < 1e-3)
						{
							if($peptides{$pep}!~/\w/) { if ($protein_peptides{$protein_name}!~/#$pep#/) { $protein_peptides{$protein_name}.="#$pep#"; } }
						}
					}
				}
				close(IN);
			}
		}
	}
	my $dir0_=$dir0;
	$dir0_=~s/^.*\/([^\/]+)$/$1/; 
	my $dir1_=$dir1;
	$dir1_=~s/^.*\/([^\/]+)$/$1/;
	open(OUT,qq!>$dir2/$dir0_-$dir1_.txt!) || "could not open file";
	open(OUT1,qq!>$dir2/$dir0_-$dir1_.fasta!) || "could not open file";
	foreach $protein_name (keys %protein_peptides)
	{
		if ($protein_name!~/\:reversed$/ and $protein_desc{$protein_name}!~/\:reversed$/ and $protein_peptides{$protein_name}=~/##/) # Not reversed and has two peptides
		{
			my $temp = $protein_peptides{$protein_name};
			while($temp=~s/^#([^\#]+)#//)
			{
				my $peptide=$1;
				print OUT qq!>$protein_name $protein_desc{$protein_name}\n$peptide\n!;
			}
			print OUT1 qq!>$protein_name $protein_desc{$protein_name}\n$protein_sequences{$protein_name}\n!;
		}
	}
	#print OUT qq!count = $count\n!;
	close(OUT);
	close(OUT1);
}
	