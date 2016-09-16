#!c:/perl/bin/perl.exe
# This program takes a protein name from rat-mouse.txt and compares
# it with protein names in mouse_e.fasta. If the name exists, it writes 
# the protein name along with the sequence into another file with the protein name.
#
use strict;

my $filename="";
my $dir="";
my $line="";
my $protein_name="";
my $protein="";
if ($ARGV[0]=~/\w/) { $filename="$ARGV[0]";} else { print "mention file";} 
if ($ARGV[1]=~/\w/) { $dir="$ARGV[1]";} else { $dir=".";} 
open (IN,qq!$filename!) || die "could not open input file\n"; 
while ($line=<IN>)
{
	if($line=~/^\>([A-Z0-9\_]+)\s/)
	{
		$protein_name=$1; 
		close(OUT);
		open (OUT,qq!>$dir/$protein_name.fasta!) || die "could not open $protein_name file\n";
	}
	elsif($line=~/^\>IPI\:([A-Z0-9]+)\./)
	{
		$protein_name=$1; 
		close(OUT); 
		open (OUT,qq!>$dir/$protein_name.fasta!) || die "could not open $protein_name file\n"; 
				
	}
	elsif($line=~/\>sp\|([A-Z0-9\_]+)\|/)
	{
		$protein_name=$1; 
		close(OUT); 
		open (OUT,qq!>$dir/$protein_name.fasta!) || die "could not open $protein_name file\n"; 	
	}
	elsif($line=~/([A-Z]+)/) 
	{
		print OUT qq!>$protein_name\n!;
		print OUT qq!$line!;
		close(OUT);
	} 
}
close(IN);