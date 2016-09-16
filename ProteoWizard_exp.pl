#!/usr/local/bin/perl
use XML::Simple;
use Data::Dumper;
use strict;

my $error=0;
my $filename_exp="";
my $method="";
my $del="";

if ($ARGV[0]=~/\w/) { $filename_exp="$ARGV[0]";} else { $error=0; }
if ($ARGV[1]=~/\w/) 
{ 
	$method="$ARGV[1]";
	$method=~s/\#/\"/g;
} 
else { $method=qq!--filter "msLevel 2-" --filter "peakPicking true 1-" --filter "threshold count 100 most-intense"!; } 
if ($ARGV[2]=~/\w/) { $del="$ARGV[2]";} else { $del=""; }

if ($error==0)
{
	my $experiment = XMLin("$filename_exp", forcearray=>[ 'group', 'sample', 'file' ]);
	my $local_dir="."; if ($filename_exp=~/^(.*)\/([^\/]+)$/) { $local_dir=$1; }
	$local_dir=~s/\\/\//g;
	my $local_dir_=$local_dir;
	$local_dir_=~s/\//\\/g;
	my $filename_exp_=$filename_exp;
	if ($filename_exp_=~/_step([0-9]+)\.xml$/i) { my $k=$1; $k++; $filename_exp_=~s/_step([0-9]+)\.xml$/_step$k.xml/i; } else { $filename_exp_=~s/\.xml$/_step1.xml/i; }
	if (open(OUT,">$filename_exp_"))
	{
		print OUT qq!<experiment>\n!;
		foreach my $group (@{$experiment->{group}})
		{
			my $group_id = $group->{id_};
			print OUT qq!\t<group id_="$group_id">\n!;
			foreach my $sample (@{$group->{sample}})
			{
				my $sample_id = $sample->{id_};
				print OUT qq!\t\t<sample id_="$sample_id">\n!;
				foreach my $file (@{$sample->{file}})
				{
					my $filename=$file->{path};
					if ($filename=~/\.raw$/i)
					{
						$filename=~s/^.*[\/\\]([^\/\\]+)$/$1/;
						print qq!###D:\\Server\\ProteoWizard\\msconvert "$local_dir\\$filename" --mzXML $method -o "$local_dir"###\n!;
						system(qq!D:\\Server\\ProteoWizard\\msconvert "$local_dir\\$filename" --mzXML $method -o "$local_dir" > "$local_dir_\\ProteoWizard.log"!);
						system(qq!del "$local_dir_\\ProteoWizard.log"!);       
						if ($del=~/^del/) { system(qq!del "$local_dir_\\$filename"!); }
						my $filename_=$filename;
						$filename_=~s/\.raw$/.mzXML/i;    
						if (open(TEST,"$local_dir/$filename_"))
						{
							close(TEST);
							print OUT qq!\t\t\t<file path="$local_dir/$filename_" />\n!;
						}
						else { print qq!Could not open $local_dir/$filename_\n!; }
					} else { print qq!Not a raw file: $filename\n!; }
				}
				print OUT qq!\t\t</sample>\n!;
			}
			print OUT qq!\t</group>\n!;
		}
		print OUT qq!</experiment>\n!;
		close(OUT);
	}
}

