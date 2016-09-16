#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $filename="";

if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $error=1; }

my %mapping = (	"TTT"=>"F","TTC"=>"F","TTA"=>"L","TTG"=>"L",
				"CTT"=>"L","CTC"=>"L","CTA"=>"L","CTG"=>"L",
				"ATT"=>"I","ATC"=>"I","ATA"=>"I","ATG"=>"M",
				"GTT"=>"V","GTC"=>"V","GTA"=>"V","GTG"=>"V",
				
				"TCT"=>"S","TCC"=>"S","TCA"=>"S","TCG"=>"S",
				"CCT"=>"P","CCC"=>"P","CCA"=>"P","CCG"=>"P",
				"ACT"=>"T","ACC"=>"T","ACA"=>"T","ACG"=>"T",
				"GCT"=>"A","GCC"=>"A","GCA"=>"A","GCG"=>"A",
				
				"TAT"=>"Y","TAC"=>"Y","TAA"=>"*","TAG"=>"*",
				"CAT"=>"H","CAC"=>"H","CAA"=>"Q","CAG"=>"Q",
				"AAT"=>"N","AAC"=>"N","AAA"=>"K","AAG"=>"K",
				"GAT"=>"D","GAC"=>"D","GAA"=>"E","GAG"=>"E",
				
				"TGT"=>"C","TGC"=>"C","TGA"=>"*","TGG"=>"W",
				"CGT"=>"R","CGC"=>"R","CGA"=>"R","CGG"=>"R",
				"AGT"=>"S","AGC"=>"S","AGA"=>"R","AGG"=>"R",
				"GGT"=>"G","GGC"=>"G","GGA"=>"G","GGG"=>"G");
				
if ($error==0)
{
	open (OUT,">$filename.fasta");
	open (LOG,">$filename.fasta.log");
	my $line="";
	my %chr=();
	my %bed=();
	my %seq=();
	if (open (IN,"$filename"))
	{
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/)
			{
				my $chr=$1;
				my $name=$4;
				$bed{$name}=$line;
				$chr{$chr}.="#$name#";
			} else { print LOG qq!Error parsing: $line!; }
		}
		close(IN);
	}
	foreach my $chr (sort keys %chr)
	{
		print qq!$chr\n!;
		if (open (IN,"genome/$chr.fa"))
		{
			print qq!opened $chr\n!;
			my $sequence="";
			$line=<IN>;
			chomp($line);
			if ($line=~/^>$chr\s*$/)
			{
				while ($line=<IN>)
				{
					chomp($line);
					if ($line=~/^>/)
					{
						print qq!Error: > not expected: $line\n!;
					}
					else
					{
						$line=~s/\s+//g;
						if ($line!~/^[atcgATCGnN]+$/)
						{
							print qq!Error: unexpected character: $line\n!;
						}
						else
						{
							$sequence .= "\U$line";
						}
					}
				}
				my $temp=$chr{$chr};
				while ($temp=~s/^#([^#]+)#//)
				{
					my $name=$1;
					print LOG qq!\n$name: $bed{$name}\n!;
					if ($bed{$name}=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/)
					{
						my $start=$2;
						my $strand=$6;
						my $num=$10;
						my $segment_lengths="$11,";
						my $segment_starts="$12,";
						my $seq="";
						while ($segment_starts=~s/^([0-9]+)\,//)
						{
							my $segment_start=$1;
							if ($segment_lengths=~s/^([0-9]+)\,//)
							{
								my $segment_length=$1;
								my $seq_=substr $sequence,$start+$segment_start,$segment_length;
								print LOG qq!$start+$segment_start,$segment_length: $seq_\n!;
								$seq.=$seq_; 
							} else { print qq!Error parsing $bed{$name}\n!; }
						}
						if ($strand=~/\-/)
						{
							my $seq_ = reverse $seq;
							$seq=$seq_;
							$seq=~tr/ATCG/TAGC/;
						}
						my $length=length($seq);
						my $protein="";
						for(my $n=0;$n<$length;$n=$n+3)
						{
							my $triplet = substr($seq, $n, 3);
							if ($mapping{$triplet}=~/[\w\*]/) { $protein.=$mapping{$triplet}; } else { $protein.="X"; }
						}
						print OUT qq!>$name\n$protein\n!;
					} else { print qq!Error parsing $bed{$name}\n!; }
				}
			} else { print qq!Error in name $chr: $line\n!; }
			
			close(IN);
		}
	}
}