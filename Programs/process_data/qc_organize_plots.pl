#!c:/perl64/bin/perl.exe

use strict;

my $dir=$ARGV[0];
$dir=~s/\\/\//g;
my $dir_=$dir;
$dir_=~s/\//\\/g;
my $dir__=$dir;
$dir__=~s/^.*\/([^\/]+)$/$1/;
mkdir("$dir/plots");
mkdir("$dir/plots/data");
my $mzxml_mz=0;
my $mzxml_scan=0;
my $mzxml_charge=0;
my $mgf_mz=0;
my $mgf_charge=0;
my $mgf_scan=0;
if (opendir(dir,"$dir"))
{
	my @allfiles=readdir dir;
	closedir dir;
	foreach my $filename (@allfiles)
	{
		if ($filename=~/\.mzXML\.mz\.png$/i) { $mzxml_mz=1; }
		if ($filename=~/\.mgf\.mass\.png$/i) { $mgf_mz=1; }
		if ($filename=~/\.mzXML\.scan\.png$/i) { $mzxml_scan=1; }
		if ($filename=~/\.mgf\.scan\.png$/i) { $mgf_scan=1; }
		if ($filename=~/\.mzXML\.charge\.png$/i) { $mzxml_charge=1; }
		if ($filename=~/\.mgf\.charge\.png$/i) { $mgf_charge=1; }
	}
}
if ($mzxml_mz==1)
{
	mkdir("$dir/plots/data/mzxml_mz");
	system(qq!move "$dir_\\*.mzxml.mz.png" "$dir_\\plots\\data\\mzxml_mz"!);
}
if ($mgf_mz==1)
{
	mkdir("$dir/plots/data/mgf_mz");
	system(qq!move "$dir_\\*.mgf.mass.png" "$dir_\\plots\\data\\mgf_mz"!);
}
if ($mzxml_charge==1)
{
	mkdir("$dir/plots/data/mzxml_charge");
	system(qq!move "$dir_\\*.mzxml.charge.png" "$dir_\\plots\\data\\mzxml_charge"!);
}
if ($mgf_charge==1)
{
	mkdir("$dir/plots/data/mgf_charge");
	system(qq!move "$dir_\\*.mgf.charge.png" "$dir_\\plots\\data\\mgf_charge"!);
}
if ($mzxml_scan==1)
{
	mkdir("$dir/plots/data/mzxml_scan");
	system(qq!move "$dir_\\*.mzxml.scan.png" "$dir_\\plots\\data\\mzxml_scan"!);
}
if ($mgf_scan==1)
{
	mkdir("$dir/plots/data/mgf_scan");
	system(qq!move "$dir_\\*.mgf.scan.png" "$dir_\\plots\\data\\mgf_scan"!);
}
