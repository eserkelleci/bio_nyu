#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $dir="";

if ($ARGV[0]=~/\w/) { $dir=$ARGV[0];} else { $dir="."; }

if ($error==0)
{
	mkdir("$dir/cleaned");
	opendir(DIR,"$dir");
	my @files = readdir DIR;
	closedir DIR;
	foreach my $filename (@files)
	{
		if ($filename=~/\.fasta$/i)
		{
			if (open (IN,"$dir/$filename"))
			{
				if (open (OUT,">$dir/cleaned/$filename"))
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
								print OUT qq!>$name $description\n!;
								while($sequence=~s/^(................................................................................)//)
								{
									print OUT qq!$1\n!;
								}
								if ($sequence=~/\w/) { print OUT qq!$sequence\n!; }
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
						print OUT qq!>$name $description\n!;
						while($sequence=~s/^(................................................................................)//)
						{
							print OUT qq!$1\n!;
						}
						if ($sequence=~/\w/) { print OUT qq!$sequence\n!; }
					}
					close(OUT);
				}
				close(IN);
			}
		}
	}
}
