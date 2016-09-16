#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $filename="";

if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $error=1; }

if ($error==0)
{
	if (open (IN,"$filename"))
	{
		if (open (OUT,">$filename+rev.fasta"))
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
						my $rev_sequence = reverse $sequence;
						print OUT qq!>$name $description\n!;
						while($sequence=~s/^(................................................................................)//)
						{
							print OUT qq!$1\n!;
						}
						if ($sequence=~/\w/) { print OUT qq!$sequence\n!; }
						
						print OUT qq!>rev_$name reversed\n!;
						while($rev_sequence=~s/^(................................................................................)//)
						{
							print OUT qq!$1\n!;
						}
						if ($rev_sequence=~/\w/) { print OUT qq!$rev_sequence\n!; }
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
						my $rev_sequence = reverse $sequence;
						print OUT qq!>$name $description\n!;
						while($sequence=~s/^(................................................................................)//)
						{
							print OUT qq!$1\n!;
						}
						if ($sequence=~/\w/) { print OUT qq!$sequence\n!; }
						
						print OUT qq!>rev_$name reversed\n!;
						while($rev_sequence=~s/^(................................................................................)//)
						{
							print OUT qq!$1\n!;
						}
						if ($rev_sequence=~/\w/) { print OUT qq!$rev_sequence\n!; }
					}
			close(OUT);
		}
		close(IN);
	}
}
