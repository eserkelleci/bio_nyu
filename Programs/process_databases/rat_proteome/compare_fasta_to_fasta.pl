#!c:/perl/bin/perl.exe
# This program determines the peptides sequences and 
# the count of such sequences present in
# mouse, rat and uniprot fasta file but not in ensembl rat fasta file
#
use strict;

my $error=0;
my $textfile="";
my $fastafile="";
my $line="";
my $dir="";
my $peptide="";
my %proteins=();
my %fastaproteins=();
my %done_proteins=();
my $protein_name="";
my $protein_desc="";
if ($ARGV[0]=~/\w/) { $textfile=$ARGV[0];} else { $error=1; } 
if ($ARGV[1]=~/\w/) { $fastafile=$ARGV[1];} else { $error=1; }  
if ($ARGV[2]=~/\w/) { $dir=$ARGV[2];} else { $error=1; } 
my $Textfile=$textfile;
$Textfile=~s/\.txt//g; 
if ($error==0)
{
	open (IN,qq!$fastafile!) || die "Could not open $fastafile\n";
	while ($line=<IN>)
	{
		if ($line=~/^\>(\S+)/)
		{
			$protein_name=$1;
		}
		if ($line=~/^([A-Z]+)/)
		{
			$line=~s/\n//g;
			$line=~tr/I/L/;
			$fastaproteins{$protein_name}.=$line;
		}
	}
	close(IN);
	
	open (IN,qq!$Textfile.fasta!) || die "Could not open $Textfile\n";
	while ($line=<IN>)
	{
		if ($line=~/^\>(\S+)\s*(.*)/)
		{
			$protein_name=$1;
			$protein_desc=$2;
			$done_proteins{$protein_name}=0;
		}
		elsif ($line=~/^([A-Z]+)/)
		{
			
			$line=~tr/I/L/;
			$proteins{$protein_name}=$line; 
		}
	}
	close(IN);
	 
	my $textfile_=$Textfile;
	$textfile_=~s/^.*\/([^\/]+)$/$1/; 
	open (IN,qq!$textfile!) || die "Could not open $textfile\n";
	open (OUT,qq!>$dir/$textfile_.output.fasta!) || die "Could not open output\n";
	while ($line=<IN>)
	{
		chomp($line);
		if ($line=~/^\>(\S+)\s*(.*)$/)
		{
			$protein_name=$1;
			$protein_desc=$2;
		}
		elsif ($line=~/^([A-Z]+)/)
		{
			$peptide=$1;
			$peptide=~tr/I/L/;
			my $flag=0; 
			foreach my $fasprot(keys %fastaproteins)	
			{
				if($fastaproteins{$fasprot}=~ m/$peptide/) {$flag=1; }
			}
			if($flag==0 and $done_proteins{$protein_name}==0) 
			{
				print OUT qq!>$protein_name $protein_desc\n$proteins{$protein_name}!; 
				$done_proteins{$protein_name}=1;
			} 
		}
	}
	close(IN);
	close(OUT);
}
	