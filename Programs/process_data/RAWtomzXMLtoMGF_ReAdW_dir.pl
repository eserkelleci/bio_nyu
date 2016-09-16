#!/usr/local/bin/perl

$error=0;
if ($ARGV[0]=~/\w/) { $dir_remote="$ARGV[0]";} else { $dir_remote="."; }
if ($ARGV[1]=~/\w/) { $dir_local="$ARGV[1]";} else { $dir_local="."; }
if ($ARGV[2]=~/\w/) { $mslevel="$ARGV[2]";} else { $mslevel="2"; }
if ($ARGV[3]=~/\w/) { $type="$ARGV[3]";} else { $type="CID"; }

if ($error==0)
{
	$dir_remote_=$dir_remote;
	if ($dir_remote_=~s/\/proteomics\/data\//\/proteomics\/results\//)
	{
		if (opendir(dir,"$dir_local"))
		{
			my @allfiles=readdir dir;
			closedir dir;
			$found=0;
			foreach $filename (@allfiles)
			{
				if ($filename=~/\.RAW$/i or $filename=~/\.mzXML$/i)
				{
					$found=1;
				}
			}
			if ($found==0)
			{
				system(qq!D:\\Server\\puTTY\\psftp_dir.pl $dir_local $dir_remote ".RAW" get!);
				system(qq!D:\\Server\\ReAdW\\ReAdW_dir.pl $dir_local!);
				system(qq!del $dir_local\\*.raw!);
				system(qq!D:\\Server\\puTTY\\psftp_dir.pl $dir_local $dir_remote ".mzXML" put!);
				system(qq!D:\\Programs\\process_data\\mzXMLtoMGF_dir.pl $dir_local!);
				system(qq!del $dir_local\\*.mzXML!);
			}
		}
	}
}


