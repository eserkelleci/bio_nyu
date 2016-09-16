#!/usr/local/bin/perl
#-------------------------------------------------------------------------#
#   This program reads in a chromosome file and converts the sequence into
#   corresponding amino acid sequence.
#
#-------------------------------------------------------------------------#
#use warnings;
use strict;

my $error=0;
my $filename="";
my $FileName="";
my $FileName_="";
my $line="";
my $name="";
my $sequence="";
my $flag=0;
my $lines="";
my %converter=();

%converter = ("TTT"=>"F","TTC"=>"F","TTA"=>"L","TTG"=>"L","CTT"=>"L","CTC"=>"L","CTA"=>"L","CTG"=>"L","ATT"=>"I","ATC"=>"I","ATA"=>"I","ATG"=>"M",
"GTT"=>"V","GTC"=>"V","GTA"=>"V","GTG"=>"V","TCT"=>"S","TCC"=>"S","TCA"=>"S","TCG"=>"S","CCT"=>"P","CCC"=>"P","CCA"=>"P","CCG"=>"P","ACT"=>"T","ACC"=>"T","ACA"=>"T",
"ACG"=>"T","GCT"=>"A","GCC"=>"A","GCA"=>"A","GCG"=>"A","TAT"=>"Y","TAC"=>"Y","TAA"=>"*","TAG"=>"*","CAT"=>"H","CAC"=>"H","CAA"=>"Q","CAG"=>"Q","AAT"=>"N","AAC"=>"N",
"AAA"=>"K","AAG"=>"K","GAT"=>"D","GAC"=>"D","GAA"=>"E","GAG"=>"E","TGT"=>"C","TGC"=>"C","TGA"=>"*","TGG"=>"W","CGT"=>"R","CGC"=>"R","CGA"=>"R","CGG"=>"R","AGT"=>"S",
"AGC"=>"S","AGA"=>"R","AGG"=>"R","GGT"=>"G","GGC"=>"G","GGA"=>"G","GGG"=>"G");
if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $error=1; }
$FileName=$filename;
$FileName=~s/\.fa//g;
if($FileName=~/([a-zA-Z0-9]+)$/) { $FileName_ = $1; }

if(open (IN, qq!$filename!))
{
	while($line = <IN>)
	{
		chomp($line);
		if($line =~/\>.*/) { $name = $line; }
		else { $sequence .= $line; }
	}
} close(IN);
my $size = length($sequence);
my $n = $size;
my $revsequence="";
while($n >= 0)
{
	my $datarev = substr($sequence, $n, 1);
	if( $datarev eq 'A' or  $datarev eq 'a') { $revsequence .= 'T' }
	elsif( $datarev eq 'C' or  $datarev eq 'c') { $revsequence .= 'G' }
	elsif( $datarev eq 'G' or  $datarev eq 'g') { $revsequence .= 'C' }
	elsif( $datarev eq 'T' or  $datarev eq 't') { $revsequence .= 'A' }
	else { $revsequence .= 'N' }
	$n =$n - 1;
}

for(my $frame=1;$frame<=3;$frame++)
{
	open (OUT,qq!>$FileName.fr$frame.fasta!);
	my $protein="";
	$n=0;
	my $n_start=1;
	while($n < $size)
	{
		my $data = uc(substr($sequence, $n+$frame-1, 3));
		$n =$n + 3; 
		if($converter{$data}=~/\w/ and $data =~ m/(A|T|G|C)/ and $converter{$data}!~/\*/) 
		{ 
			$protein .= $converter{$data};
		}
		else 
		{
			if (length($protein)>6)
			{
				my $protein_length=length($protein);
				my $n_end=(($n_start-1)+(3*$protein_length));
				print OUT qq!>$FileName_\_f$frame.$n_start-$n_end\n$protein\n!;
			}
			$n_start=$n+1;
			$protein="";
		}
	}
	if (length($protein)>6)
	{
		my $protein_length=length($protein);
		my $n_end=(($n_start-1)+(3*$protein_length));
		print OUT qq!>$FileName_\_f$frame.$n_start-$n_end\n$protein\n!;
	}
	close(OUT);
}

for(my $frame=1;$frame<=3;$frame++)
{
	open (OUT,qq!>$FileName.revfr$frame.fasta!);
	my $protein="";
	$n=0;
	my $n_start=1;
	while($n < $size)
	{
		my $data = uc(substr($revsequence, $n+$frame-1, 3));
		$n =$n + 3; 
		if($converter{$data}=~/\w/ and $data =~ m/(A|T|G|C)/ and $converter{$data}!~/\*/) 
		{ 
			$protein .= $converter{$data};
		}
		else 
		{
			if (length($protein)>6)
			{
				my $protein_length=length($protein);
				my $n_end = $size-$n_start-3*$protein_length+3;
				my $n_start_= $size-$n_start+2;
				print OUT qq!>$FileName_\_r$frame.$n_start_-$n_end\n$protein\n!;
			}
			$n_start=$n+1;
			$protein="";
		}
	}
	if (length($protein)>6)
	{
		my $protein_length=length($protein);
		my $n_end = $size-$n_start-3*$protein_length+3;
		my $n_start_= $size-$n_start+2;
		print OUT qq!>$FileName_\_r$frame.$n_start_-$n_end\n$protein\n!;
	}
	close(OUT);
}