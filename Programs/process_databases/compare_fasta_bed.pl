#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $filename_fasta="";
my $filename_bed="";

if ($ARGV[0]=~/\w/) { $filename_fasta=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $filename_bed=$ARGV[1];} else { $error=1; }
	
if ($error==0)
{
	open (LOG,">$filename_fasta.fasta-bed.log");
	my $line="";
	my %chr=();
	my %bed=();
	my %seq=();
	my $bed_count=0;
	my $fasta_count=0;
	my $fasta_found_count=0;
	if (open (IN,"$filename_bed"))
	{
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/)
			{
				my $chr=$1;
				my $name=$4;
				$name=~s/^.*\-([^\-]+)$/$1/;
				$bed{$name}=$line;
				$chr{$chr}.="#$name#";
				$bed_count++;
			} else { print LOG qq!Error parsing: $line!; }
		}
		close(IN);
	}
	if (open (IN,"$filename_fasta"))
	{
		my $name="";
		my $description="";
		my $sequence="";
		my $line="";
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^>\s*(\S+)\s?(.*)$/)
			{
				my $name_=$1;
				my $description_=$2;
				if ($name=~/\w/ and $sequence=~/\w/)
				{
					$name=~s/^gi\|[0-9]+//;
					$name=~s/^\|ref\|//;
					$name=~s/\|$//;
					$name=~s/\..*$//;
					if ($bed{$name}=~/\w/) { $fasta_found_count++; } else { print LOG qq!Mapping not found: $name\n!; }
					$fasta_count++;
				}
				$name=$name_;
				$description=$description_;
				$sequence="";
			}
			else
			{
				$line=~s/[^A-Za-z]//gm;
				$sequence.="\U$line";
			}
		}
				if ($name=~/\w/ and $sequence=~/\w/)
				{
					$name=~s/^gi\|[0-9]+//;
					$name=~s/^\|ref\|//;
					$name=~s/\|$//;
					$name=~s/\..*$//;
					if ($bed{$name}=~/\w/) { $fasta_found_count++; } else { print LOG qq!Mapping not found: $name\n!; }
					$fasta_count++;
				}
		close(IN);
	}
	print LOG qq!$fasta_found_count out of $fasta_count sequences in $filename_fasta mapped using $filename_bed\n!;
	print qq!$fasta_found_count out of $fasta_count sequences in $filename_fasta mapped using $filename_bed\n!;
	close(LOG);
}