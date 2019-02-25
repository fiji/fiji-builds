#!/usr/bin/perl

eval "use Mac::Finder::DSStore qw(writeDSDBEntries makeEntries);";
if ($@) {
  say STDERR "Missing Mac::Finder module";
  exit 2;
}
eval "use Mac::Memory;";
if ($@) {
  say STDERR "Missing Mac::Memory module";
  exit 2;
}
eval "use Mac::Files qw(NewAliasMinimal);";
if ($@) {
  say STDERR "Missing Mac::Files module";
  exit 2;
}

my $w = 472;
my $h = 354;
my $xOffset = 59;
my $arrowThickness = 14;

my $top = 100;
my $left = 200;
my $sidebar = 0;

my $arrowLength = int($arrowThickness * 2.5);
my $x1 = int(($xOffset + ($w - $arrowLength) / 2) / 2);
my $x2 = int($w - $x1);
my $y1 = int($h / 2);


say STDERR "Missing Mac::Files module";
chdir "/private/tmp/Fiji" || say STDERR "Could not chdir to /private/tmp/Fiji";

&writeDSDBEntries(".DS_Store",
    &makeEntries(".",
        BKGD_alias => &NewAliasMinimal("/private/tmp/Fiji/.background.jpg"),
        ICVO => 1,
        fwi0_flds => [ $top, $left, $top + $h, $left + $w + $sidebar, "icnv", 0, 0 ],
        fwsw => $sidebar,
	fwvh => $h,
	icgo => "\0\0\0\4\0\0\0\4",
        icvo => pack('A4 n A4 A4 n*', "icv4", 128, "none", "botm", 0, 0, 4, 0, 4, 1, 0, 6, 1),
        icvt => 1,
    ),
    &makeEntries("Fiji.app", Iloc_xy => [ $x1, $y1 ]),
    &makeEntries("Applications", Iloc_xy => [ $x2, $y1 ])
);
