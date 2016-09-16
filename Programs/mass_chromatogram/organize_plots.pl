#!c:/perl64/bin/perl.exe

$dir=$ARGV[0];
$dir=~s/\\/\//g;
$dir_=$dir;
$dir_=~s/\//\\/g;
$dir__=$dir;
$dir__=~s/^.*\/([^\/]+)$/$1/;

mkdir("$dir/$dir__-plots");
mkdir("$dir/$dir__-plots/pep");

if (opendir(dir,"$dir"))
{
	my @alldirs=readdir dir;
	closedir dir;
	foreach $dir___ (@alldirs)
	{
		if ($dir___=~/\w/ and $dir___!~/^pep$/)
		{
			if (opendir(dir,"$dir/$dir___"))
			{
				my @allfiles=readdir dir;
				closedir dir;
				foreach $filename (@allfiles)
				{
					if ($filename=~/\.png$/i and $filename!~/_zoom\.png$/i)
					{
						$dir____=$dir___;
						$dir____=~s/\..*$//;
						$pep=$filename;
						$pep=~s/_.*$//;
						$pep{$pep}.=qq!#"$dir_\\$dir___\\$filename" "$dir_\\$dir__-plots\\pep\\$pep\\$dir____-$filename"#!;
						#print "$dir__ $pep\n";
					}
				}
			}
		}
	}
}

#foreach $pep (sort keys %pep)
#{
#	mkdir("$dir/organized/pep/$pep");
#	print "$pep\n";
#	$temp=$pep{$pep};
#	while ($temp=~s/^#([^#]+)#//)
#	{
#		system(qq!copy $1!);
#	}
#}