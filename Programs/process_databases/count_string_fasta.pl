#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $dir="";
my $string="";
my $count=0;

if ($ARGV[0]=~/\w/) { $dir=$ARGV[0];} else { $dir="."; }
if ($ARGV[1]=~/\w/) { $string=$ARGV[1];} else { $error=1; }

$string=~tr/L/I/;
if ($error==0)
{
	opendir(DIR,"$dir");
	my @files = readdir DIR;
	closedir DIR;
	foreach my $filename (@files)
	{
		if ($filename=~/\.fasta$/i)
		{
			if (open (IN,"$dir/$filename"))
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
							$sequence=~tr/L/I/;
							if ($sequence=~/$string/) { $count++; }
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
							$sequence=~tr/L/I/;
							if ($sequence=~/$string/) { $count++; }
				}
				close(IN);
			}
		}
	}
}
print qq!$dir\t$string\t$count\n!;
