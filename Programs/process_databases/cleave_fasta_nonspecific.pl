#!/usr/local/bin/perl
#

$error=0;
if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $filename="gag.fasta"; }
if ($ARGV[1]=~/\w/) { $min_length=$ARGV[1];} else { $min_length=9; }
if ($ARGV[2]=~/\w/) { $max_length=$ARGV[2];} else { $max_length=25; }
if ($ARGV[3]=~/\w/) { $probability=$ARGV[3];} else { $probability=1; }

$filename_=$filename;
if ($filename_!~s/\.fasta$//i) { $error=1; }
$filename_.="-$min_length-$max_length-p$probability";
open(OUT,">$filename_.fasta");
open(OUT_,">$filename_.txt");
$peptides_count=0;
$peptides_tryptic_count=0;
$proteins_count=0;

if ($error==0)
{
	if (open (IN,"$filename"))
	{
		$name="";
		$sequence="";
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^>(\S+)\s?(.*)$/)
			{
				$name_=$1;
				$description_=$2;
				if ($name=~/\w/ and $sequence=~/\w/)
				{
					$proteins_count++;
					cut($name,$description,$sequence,$min_length,$max_length,$probability);
					if ($proteins_count%100==0) 
					{
						$ratio=10000*$peptides_tryptic_count/$peptides_count+0.5;
						$ratio=~s/\..*$//;
						$ratio/=100;
						print qq!$proteins_count $ratio\% ($peptides_tryptic_count,$peptides_count)\n!;
					}
				}
				$name=$name_;
				$description=$description_;
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
			cut($name,$description,$sequence,$min_length,$max_length,$probability);
		}
		close(IN);
	}
	print "$filename, $min_length-$max_length, $probability, $proteins_count proteins, $peptides_count peptides, $peptides_tryptic_count tryptic peptides\n";
}
close(OUT_);
close(OUT);


sub cut
{
	my $name = shift();
	my $description = shift();
	my $seq = shift();
	my $min_length = shift();
	my $max_length = shift();
	my $probability = shift();

	my $length=length($seq);
	my $l=0;
	my $start=0;

	for($l=$min_length;$l<=$max_length;$l++)
	{
		for($start=0;$start+$l<=$length;$start++)
		{
			$temp_seq=substr($seq,$start,$l);
			$tryptic=0;
			if ($start>0) { $temp_seq_before=substr($seq,$start-1,1); } else { $temp_seq_before=""; }	
			if ($start+$l+1<=$length) { $temp_seq_after=substr($seq,$start+$l,1); }  else { $temp_seq_after=""; }
			if ( 
				 ( $temp_seq_before!~/\w/ or ($temp_seq_before=~/^[KR]$/i and $temp_seq!~/^P/i) ) and 
				 ( $temp_seq_after!~/\w/ or ($temp_seq=~/[KR]$/i and $temp_seq_after!~/^P$/i) ) 
			   )
			{
				$tryptic=1;
				$peptides_tryptic_count++;
			}
			if (rand()<=$probability)
			{
				#print OUT qq!>$name\_l$l\_s$start $tryptic #$temp_seq_before#$temp_seq#$temp_seq_after\n$temp_seq\n!;
				print OUT qq!>$name\_l$l\_s$start\n$temp_seq\n!;
				print OUT_ qq!$temp_seq\n!;
				$peptides_count++;
			}

		}
	}
}

