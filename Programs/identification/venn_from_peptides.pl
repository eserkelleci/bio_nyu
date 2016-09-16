#!c:/perl/bin/perl.exe
#
use strict;

my $print_peptides=1;

my $error=0;
my $filename1="";
my $filename2="";
my $filename3="";
if ($ARGV[0]=~/\w/) { $filename1=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $filename2=$ARGV[1];} else { $error=1; }
if ($ARGV[2]=~/\w/) { $filename3=$ARGV[2];} else { ; }

my $line="";
my %pep=();
my %groups=();

if ($error==0)
{
	if (open (IN,qq!$filename1!))
	{
		while ($line=<IN> and $error==0)
		{
			chomp($line);
			if ($line=~/^([^\t]+)/)
			{
				my $pep=$1;
				if ($pep{$pep}!~/1/) { $pep{$pep}.="1"; }
			}
		}
		close(IN);
	}
	if (open (IN,qq!$filename2!))
	{
		while ($line=<IN> and $error==0)
		{
			chomp($line);
			if ($line=~/^([^\t]+)/)
			{
				my $pep=$1;
				if ($pep{$pep}!~/2/) { $pep{$pep}.="2"; }
			}
		}
		close(IN);
	}
	if (open (IN,qq!$filename3!))
	{
		while ($line=<IN> and $error==0)
		{
			chomp($line);
			if ($line=~/^([^\t]+)/)
			{
				my $pep=$1;
				if ($pep{$pep}!~/3/) { $pep{$pep}.="3"; }
			}
		}
		close(IN);
	}
	
	if ($print_peptides==1) 
	{ 
		open (OUT,qq!>$filename1.venn-unique.txt!); 
		open (OUT_ALL,qq!>venn-12.txt!); 
	}
	foreach my $pep (keys %pep)
	{
		$groups{$pep{$pep}}++;
		if ($print_peptides==1)
		{
			if ($pep{$pep}=~/^1$/)
			{
				print OUT qq!$pep\n!;
			}
			if ($pep{$pep}=~/^12$/)
			{
				print OUT_ALL qq!$pep\n!;
			}
		}
	}
	if ($print_peptides==1) 
	{ 
		close(OUT); 
		close(OUT_ALL); 
	}
	
	foreach my $group (sort keys %groups)
	{
		print qq!$group\t$groups{$group}\n!;
	}
}
