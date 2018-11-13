#!/usr/bin/perl
# Copyleft: R.Jaksa 2018, GNU General Public License version 3
# include "CONFIG.pl"
use v5.10; # for state
use Time::HiRes qw(usleep time);
use IO::Handle qw( ); STDOUT->autoflush(1);
# ------------------------------------------------------------------------------- HELP

$HELP=<<EOF;

NAME
    evgen - event generator

USAGE
    evgen [OPTIONS] [NUM]

DESCRIPTION
    Evgen generates a stream of NUM events, or infinite loop without NUM specified.
    Events consist from action and context.  Events generation policies are:

    1. random - choose any random event,
    2. steps - loop from the event-1 to the event-N and again,
    3. from file - wait until the event number is provided in the file.

OPTIONS
          -h  This help.
          -v  Verbose execution using CD(STDERR).

     -t=MSEC  Interval between events in milliseconds CK((default none).)
         -nt  No timestamps.
         -nm  No meta-information header.

      -e=NUM  Number of possible events CK((default 2: event 1 and event 2).)
      -c=NUM  Dimensionality of the context vector CK((default 0 = no_context).)
     -cn=NUM  Number of context states CK((default 2: 0 and 1).)
  CC(-i=NUM,NUM)  Interval of event IDs CK((default [1,No_of_events]).)
 CC(-ci=NUM,NUM)  Interval of context values CK((default [0,Context_states-1]).)

random policy:
          -r  Choose the event randomly CK((default).)
         -cr  Choose the context randomly CK((default).)
      -r=NUM  Produce the same random event NUM times.
     -cr=NUM  Produce the same random context NUM times.

steps policy:
      -s=NUM  Cycle events in steps with the NUM events in each.
     -cs=NUM  Cycle context in steps with the NUM events in each.
          -s  Steps of 100 events.
         -cs  Steps of 10 contexts.

from-file policy:
     -f=FILE  File to read the event ID from.  After any close operation
              the file will be inspected.  The last number from the last
              line will be used as the requested event ID.

META-INFORMATION
    Comment on the first line in output is used to indicate columns names:

        CC(date)  ISO 8601 current local date
        CC(time)  ISO 8601 current local time
          CC(a1)  actions one CK((the 1st dimension of actions vector))
          CC(a2)  actions two CK((the 2nd dimension of actions vector))
          CC(c1)  context one CK((the 1st dimension of context vector))
          CC(c2)  context two CK((the 2nd dimension of context vector))

EOF

# ---------------------------------------------------------------------------- VERBOSE

sub error {
  my $s=$_[0]; $s=~s/\n$//;
  print STDERR "$CR_$s$CD_\n"; }

sub debug {
  my $s=$_[1]; $s=~s/\n$//;
  printf STDERR "%7s: %s\n",$_[0],$s if $DEBUG; }

sub verbn { print  STDERR "\n"; }
sub verb2 { printf STDERR "$CK_%22s: %s$CD_\n",$_[0],$_[1]; }
sub verb3 { printf STDERR "$CK_%22s: %s %s$CD_\n",$_[0],$_[1],$_[2]; }

# ------------------------------------------------------------------------------- MATH

# just round the number
sub round {
  return int($_[0] + $_[0]/abs($_[0]*2 || 1)); }

# print number with max two decimal places
sub dec2 {
  my $r = sprintf("%.2f",$_[0]);
  $r =~ s/0+$// if $r =~ /\./;
  $r =~ s/\.$//;
  $r = 0 if $r eq "-0";
  return $r; }

# ------------------------------------------------------------------------------ ARGVS
foreach(@ARGV) { if($_ eq "-h") { printhelp $HELP; exit 0; }}
foreach(@ARGV) { if($_ eq "-v") { $VERBOSE=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-d") { $DEBUG=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-nt") { $NOTS=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-nm") { $NOMETA=1; $_=""; last; }}

our $MSEC;
foreach(@ARGV) { if($_ =~ /^-t=([0-9]+)$/) { $MSEC=$1; $_=""; last; }}

# events

our $EVENTS;
foreach(@ARGV) { if($_ =~ /^-e=([0-9]+)$/) { $EVENTS=$1; $_=""; last; }}

our ($EMIN,$EMAX);
foreach(@ARGV) { if($_ =~ /^-i=([0-9]+),([0-9]+)$/) { $EMIN=$1; $EMAX=$2; $_=""; last; }}

our $ERAND;
foreach(@ARGV) { if($_ eq "-r") { $ERAND=1; $_=""; last; }}
foreach(@ARGV) { if($_ =~ /^-r=([0-9]+)$/) { $ERAND=$1; $_=""; last; }}

our $ESTEP;
foreach(@ARGV) { if($_ eq "-s") { $ESTEP=100; $_=""; last; }}
foreach(@ARGV) { if($_ =~ /^-s=([0-9]+)$/) { $ESTEP=$1; $_=""; last; }}

# context

our $CONTVEC;
foreach(@ARGV) { if($_ =~ /^-c=([0-9]+)$/) { $CONTVEC=$1; $_=""; last; }}

our $CONTEXTS;
foreach(@ARGV) { if($_ =~ /^-cn=([0-9]+)$/) { $CONTEXTS=$1; $_=""; last; }}

our ($CMIN,$CMAX);
foreach(@ARGV) { if($_ =~ /^-ci=([0-9]+),([0-9]+)$/) { $CMIN=$1; $CMAX=$2; $_=""; last; }}

our $CRAND;
foreach(@ARGV) { if($_ eq "-cr") { $CRAND=1; $_=""; last; }}
foreach(@ARGV) { if($_ =~ /^-cr=([0-9]+)$/) { $CRAND=$1; $_=""; last; }}

our $CSTEP;
foreach(@ARGV) { if($_ eq "-cs") { $CSTEP=100; $_=""; last; }}
foreach(@ARGV) { if($_ =~ /^-cs=([0-9]+)$/) { $CSTEP=$1; $_=""; last; }}

# from-file
our $FROMFILE;
foreach(@ARGV) { if($_ =~ /^-f=([^ ]+)$/) { $FROMFILE=$1; $_=""; last; }}

# stop

our $STOP;
foreach(@ARGV) { if($_ =~ /^([0-9]+)$/) { $STOP=$1; $_=""; last; }}

# wrong arguments
my @wrong;
foreach(@ARGV) { push @wrong,$_ if $_ ne ""; }
if(@wrong) {
  error;
  foreach my $arg (@wrong) { error "wrong argument: $arg"; }
  error; }

# ------------------------------------------------------------------------- STOP LOGIC

our $FINITE = 1;
if(not defined $STOP) {
  $FINITE = 0;
  $MSEC = 100 if not defined $MSEC; }

# ----------------------------------------------------------------------- EVENTS LOGIC

if(not defined $EVENTS) {
  if(defined $EMIN and defined $EMAX) { $EVENTS = int($EMAX-$EMIN); }
  else { $EVENTS = 2; }}

my ($emax,$emin);
if(not defined $EMIN) {
  if(defined $EMAX) { $emin = $EMAX - $EVENTS; }
  else { $emin = 1; }}
if(not defined $EMAX) {
  if(defined $EMIN) { $emax = $EMIN + $EVENTS; }
  else { $emax = $EVENTS; }}
$EMAX = $emax if not defined $EMAX;
$EMIN = $emin if not defined $EMIN;

$ERAND = 1 if not defined $ERAND and not defined $ESTEP;

# ---------------------------------------------------------------------- CONTEXT LOGIC

if(not defined $CONTEXTS) {
  if(defined $CMIN and defined $CMAX) { $CONTEXTS = int($CMAX-$CMIN); }
  else { $CONTEXTS = 2; }}

my ($cmax,$cmin);
if(not defined $CMIN) {
  if(defined $CMAX) { $cmin = $CMAX - $CONTEXTS; }
  else { $cmin = 1; }}
if(not defined $CMAX) {
  if(defined $CMIN) { $cmax = $CMIN + $CONTEXTS; }
  else { $cmax = $CONTEXTS; }}
$CMAX = $cmax if not defined $CMAX;
$CMIN = $cmin if not defined $CMIN;

$CRAND = 1 if not defined $CRAND and not defined $CSTEP;

# ------------------------------------------------------------------------------- CORE
my ($e0,$en) = ($EMIN,$EMAX); my $ed = $en-$e0; my $es = $ed/($EVENTS-1); # event: 1 2 3 ...

if($VERBOSE) {
  my $es2 = dec2($es);
  verb2 "$EVENTS events","$e0..$en (range $ed, step $es2)"; }

# choose event
sub event {
  my $i = $_[0];  # line index
  my $es = $_[1]; # next step stop
  my $er = $_[2]; # next rand stop
  state $e = $EMIN; # return event

  # step strategy
  if(defined $ESTEP) {
    if($i>$$es) {
      $$es += $ESTEP;
      $e++;
      $e = $EMIN if $e>$EMAX; }}

  # random strategy
  elsif(defined $ERAND) {
    if($i>$$er) {
      $$er += $ERAND;
      $e = int(rand($EVENTS))+1; }}

  return $e; }

# choose context
sub context {
  my $i = $_[0];  # line index
  my $cs = $_[1]; # next step stop
  my $cr = $_[2]; # next rand stop
  state @c;	  # return context vector
  state $cok = 0;
  if(not $cok) {
    my $c0 = $CMIN;
    for(my $j=0; $j<$CONTVEC; $j++) {
      $c[$j] = $c0;
      $c0++;
      $c0 = $CMIN if $c0 > $CMAX; }
    $cok=1; }

  # main loop
  for(my $j=0; $j<$CONTVEC; $j++) {

    # step strategy
    if(defined $CSTEP) {
      if($i>$cs->[$j]) {
	$cs->[$j] += $CSTEP;
	$c[$j]++;
	$c[$j] = $CMIN if $c[$j]>$CMAX; }}

    # random strategy
    elsif(defined $CRAND) {
      if($i>$cr->[$j]) {
      $cr->[$j] += $CRAND;
      $c[$j] = int(rand($CONTEXTS))+1; }}}

  return @c; }

# timestamp
sub tstamp {

  # localtime
  my ($ly,$lm,$ld,$lH,$lM,$lS,$isdst) = (localtime)[5,4,3,2,1,0,8];
  $ly += 1900;
  $lm += 1;
  my $s = sprintf "%04d-%02d-%02d %02d:%02d:%02d",$ly,$lm,$ld,$lH,$lM,$lS;

  # add microseconds
  if($MSEC < 1000) {
    my $ht = time; # high resolution time
    my $lu = sprintf "%02d",($ht-int($ht))*100; # decimal part of second
    $s .= ".$lu"; }

  return $s; }

# status variables
my $es=$ESTEP;	# step target
my $er=$ERAND;	# rand target
my @cs;		# step target
my @cr;		# rand target

# initiate context vector parameters
for(my $j=0; $j<$CONTVEC; $j++) {
  push @cs,$CSTEP;
  push @cr,$CRAND; }

# meta line
if(not $NOMETA) {
  my $s;
  my $d = "date time " if not $NOTS;
  for(my $j=1; $j<=$CONTVEC; $j++) { $s.=" c$j"; }
  print "# ${d}a1$s\n"; }

# main loop
my $i=0;
while(1) {
  $i++;
  last if $FINITE and $i>$STOP;

  my $e; # event ID
  my $t; # timestamp
  my @c; # context vector

  # from-file
  if(defined $FROMFILE) {
    if(not -f $FROMFILE) { system "touch $FROMFILE"; }
    else {
      exit 1 if system("inotifywait -q -q -e close_write $FROMFILE") != 0; # end on ctrl-c
      my $s = `tail -n 1 $FROMFILE`;					   # just last line
      my $n; $n = $1 if $s =~ /([0-9\.-]+)\h*$/;			   # last number
      $e = $n if defined $n; }}						   # only if found, otherwise random

  $e = event($i,\$es,\$er) if not defined $e;
  $t = tstamp." " if not $NOTS;
  @c = context($i,\@cs,\@cr);
  my $c; $c.=" $_" foreach @c;

  print "$t$e$c\n";
  usleep $MSEC*1000 if defined $MSEC; }

# -------------------------------------------------------------------------------- END
