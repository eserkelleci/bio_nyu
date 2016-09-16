#!/usr/local/bin/perl

$error=0;
if ($ARGV[0]=~/\w/) { $dir="$ARGV[0]";} else { $error=1; }
if ($ARGV[1]=~/\w/) { $filter="$ARGV[1]";} else { $filter=".RAW"; }

if ($error==0)
{
	if (opendir(dir,"$dir"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		if (open(OUT,">$dir/experiment.xml"))
		{
			print OUT qq!<experiment>\n!;
			print OUT qq!\t<group id_="1">\n!;
			$count=0;
			foreach $filename (@allfiles)
			{
				if ($filename=~/$filter/i)
				{
					print OUT qq!\t\t<sample id_="$count">\n!;
					print OUT qq!\t\t\t<file path="$dir/$filename" />\n!;
					print OUT qq!\t\t</sample>\n!;
					$count++;
				}
			}
			print OUT qq!\t</group>\n!;
			print OUT qq!</experiment>\n!;
			close(OUT);
		}
	}
}
