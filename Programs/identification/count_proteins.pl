#!c:/Perl/bin/perl.exe

use strict;

my $error=0;
my $filename="";
my $db_dir="";

if ($ARGV[0]=~/\w/) { $filename="$ARGV[0]"; } else { $error=1; }
if ($ARGV[1]=~/\w/) { $db_dir="$ARGV[1]"; } else { $error=1; }

if ($error==0)
{
	open(LOG,">$filename.count_proteins.log");
	my %peptides=();
	my %peptide_score=();
	my $count_pep=0;
	my $count_pep_unique=0;
	my $line="";
	if (open(IN,"$filename"))
	{
		while($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([A-Za-z]+)\s*([0-9\+\-\.edED]+)/)
			{
				my $pep=$1;
				my $score=$2;
				$pep=~tr/L/I/;
				if ($peptide_score{"\U$pep"}!~/\w/ or $peptide_score{"\U$pep"}<$score) { $peptide_score{"\U$pep"}=$score; }
				if ($peptides{"\U$pep"}!~/\w/) { $count_pep_unique++ }
				$peptides{"\U$pep"}=1;
				$count_pep++;
			} 
			else { if ($line=~/\w/) { print LOG qq!Error: $line\n!; } }	
		}
		close(IN);
		print LOG qq!$filename\n$count_pep peptides\n!;
	}

	my %proteins=();
	if (opendir(dir,"$db_dir"))
	{
		my @dbs = readdir dir;
		closedir dir;
		foreach my $db (@dbs)
		{
			if ($db=~/\.fasta/i)
			{
				print LOG "$db\n";	
				if (open (IN,"$db_dir/$db"))
				{
					my $name="";
					my $sequence="";
					my $count_seq=0;
					while ($line=<IN>)
					{
						chomp($line);
						if ($line=~/^>(\S+)/)
						{
							my $name_=$1;
							if ($name=~/\w/ and $sequence=~/\w/)
							{
								$proteins{$name}=$sequence;
								$count_seq++;
							}
							$name=$name_;
							$sequence="";
						}
						else
						{
							$sequence.="\U$line";
						}
					}	
					if ($name=~/\w/ and $sequence=~/\w/)
					{
						$proteins{$name}=$sequence;
						$count_seq++;
					}
					close(IN);
					print LOG qq!$count_seq sequences\n!;
				}
			}
		}
	}
	
	my $count_pep_unique_=0;
	my %peptide_proteins=();
	my %protein_peptides_count=();
	my %protein_peptides=();
	my %peptide_proteins_count=();
	foreach my $pep (keys %peptides)
	{
		$peptide_proteins_count{$pep}=0;
		print qq!$count_pep_unique_ ($count_pep_unique)\n!;
		foreach my $name (keys %proteins)
		{
			my $seq=$proteins{$name};
			$seq=~tr/L/I/;
			if ($seq=~/$pep/)
			{
				$protein_peptides{$name}.="#$pep#";
				$protein_peptides_count{$name}++;
				$peptide_proteins{$pep}.="#$name#";
				$peptide_proteins_count{$pep}++;
			}
		}
		$count_pep_unique_++;
	}

	my @proteins_to_sort=();
	my $proteins_to_sort_count=0;
	foreach my $name (keys %proteins)
	{
		if ($protein_peptides_count{$name}>0) 
		{
			$proteins_to_sort[$proteins_to_sort_count]=qq!$protein_peptides_count{$name}#$name!;
			$proteins_to_sort_count++;
		}
	}
	my @proteins_sorted = sort { $b <=> $a } @proteins_to_sort;
	my $proteins_sorted_count=0;
	my %protein_peptides_unique_count=();
	my %peptides_done=();
	my $proteins_unique_count=0;
	open(OUT,">$filename.count_proteins.txt");
	open(OUT_ALL,">$filename.count_proteins.all.txt");
	for(;$proteins_sorted_count<$proteins_to_sort_count;$proteins_sorted_count++)
	{
		if ($proteins_sorted[$proteins_sorted_count]=~/#([^#]+)$/)
		{
			my $name=$1;
			$protein_peptides_unique_count{$name}=0;
			my $temp=$protein_peptides{$name};
			while($temp=~s/^#([^#]+)#//)
			{
				my $pep=$1;
				if ($peptides_done{$pep}!~/\w/)
				{
					$peptides_done{$pep}=1;
					$protein_peptides_unique_count{$name}++;
				}
			}
			if ($protein_peptides_unique_count{$name}>0)
			{
				print OUT qq!$name\t$protein_peptides_count{$name}\t$protein_peptides_unique_count{$name}\n!;
				$proteins_unique_count++;
			}
			print OUT_ALL qq!$name\t$protein_peptides_count{$name}\t$protein_peptides_unique_count{$name}\n!;
		}
	}
	close(OUT_ALL);
	close(OUT);
	
	foreach my $pep (keys %peptides)
	{
		if ($peptides_done{$pep}!=1) { print LOG qq!Peptide $pep not found\n!; }
	}
	close(LOG);
	print qq!\n$proteins_unique_count proteins\n!; 
}