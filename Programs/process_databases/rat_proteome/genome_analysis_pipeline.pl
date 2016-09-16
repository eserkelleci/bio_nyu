#!/usr/local/bin/perl
# This program automates the genome analysis starting with fasta file comparison with xml 
# and ending with blast results.
use strict;

# 1. input to program is the main directory that contains all directories with data #
my $dir="";
my @subdirectories="";

if ($ARGV[0]=~/\w/) { $dir="$ARGV[0]";} else { $dir="."; }

# 2. convert all I to L, and count the peptides not present in rat genome #
if (opendir(dir,"$dir/other"))
{
	@subdirectories=readdir dir;
	closedir dir;
}
foreach my $folders (@subdirectories)
{
	if ($folders!~/([\.]+)/i)
	{ 
		print qq!$folders\n!;
		system(qq!D://Programs//process_databases//rat_proteome//peptide_count.pl "$dir/rat" "$dir/other/$folders" "$dir/temp"!);
	}
}

# 3. compare previous output with ensemble rat fasta file and get the peptides that do not match #
if (opendir(dir,"$dir/temp"))
{
	my @alltextfiles=readdir dir;
	closedir dir;
	foreach my $textfiles (@alltextfiles)
	{
		if ($textfiles=~/\.txt$/i)
		{
			system(qq!D://Programs//process_databases//rat_proteome//compare_fasta_to_fasta.pl "$dir/temp/$textfiles" "$dir/rat/Rattus_norvegicus.RGSC3.4.64.pep.all.fasta" "$dir/temp"!);
		}
	}
}
# 4. group identical proteins together and split proteins into files #
system(qq!D://Programs//process_databases//rat_proteome//group_proteins.pl "$dir/temp"!);
mkdir("$dir/temp/fasta");
system(qq!D://Programs//process_databases//rat_proteome//split_proteins_into_files.pl "$dir/temp/grouped_proteins.fasta" "$dir/temp/fasta"!);

# 5. create the database and blast the output files using blastp and tblastn #
mkdir("$dir/addition");
mkdir("$dir/addition/tblastn");
mkdir("$dir/addition/blastp");
system(qq!D://Server//blast//ncbi-blast-2.2.25+//bin//makeblastdb.exe -in $dir/rat/ratgenome.fasta -dbtype nucl!);
system(qq!D://Server//blast//ncbi-blast-2.2.25+//bin//makeblastdb.exe -in $dir/rat/Rattus_norvegicus.RGSC3.4.64.pep.all.fasta -dbtype prot!);

system(qq!D://Programs//process_databases//rat_proteome//blast_main.pl "$dir/temp/fasta" "$dir/rat" "$dir/addition/blastp" "$dir/addition/tblastn"!);

# 6. digest the rat ensembl and fasta files, count the total tryptic peptide and the tryptic peptides that match the rat ensembl tryptic peptides #
system(qq!D://Programs//process_databases//rat_proteome//digest_proteins_count.pl "$dir/rat/Rattus_norvegicus.RGSC3.4.64.pep.all.fasta" "$dir/temp/fasta" "$dir/temp"!);
system(qq!D://Programs//process_databases//rat_proteome//digest_proteins_count.pl "$dir/rat/ratgenome.fasta" "$dir/temp/fasta" "$dir/temp"!);
