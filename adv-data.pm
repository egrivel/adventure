# $gl_data is a reference to the static data loaded from the configuration file
my $gl_data = "";

# %gl_values are the global values (which can be changing)
my %gl_values = ();

# @gl_inventory is the items being carried
my @gl_inventory = ();

# $gl_location is the current location
my $gl_location = "";

# %gl_objects is the list of objects with their current location and
# state
my %gl_objects = ();

# Declare special location ID for the 'inventory' location of objects (the
# objects being carried around).
$INVENTORY = '@inventory';

# -----------------------------------------------------------------------------
# Read the source data file.
# -----------------------------------------------------------------------------
sub read_data {
  my $fname = $_[0];

  open(FILE, "<$fname") || error("Cannot read data file '$fname'");

  my $data = "";
  while (<FILE>) {
    chomp();
    s/\r//;
    s/\/\/.*$//;
    s/^\s+//;;
    s/\s+$//;
    $data .= $_;
  }
  close FILE;

  $gl_data = decode_json($data);

  $gl_location = get_location($$gl_data{"default-location"});

  # Put all objects in their default location
  my $i;
  for ($i = 0; defined($$gl_data{"objects"}[$i]); $i++) {
    my $id = $$gl_data{"objects"}[$i]{"id"};
    my $location = $$gl_data{"objects"}[$i]{"default-location"};
    move_object($id, $location);
  }
}

# -----------------------------------------------------------------------------
# Location functions
# Locations are all in the source data, and don't change. The location
# functions operate on the source data tree.
# 
# Functions are:
#  - get_location($location_id) returns the location object, or undef
#  - get_current_location() returns the current location object
#  - get_current_location_id() returns the current location ID
#  - set_current_location($location) sets the current location to the object
#  - set_current_location_id($id) sets the current location to the ID
# -----------------------------------------------------------------------------

sub get_location {
  my $id = $_[0];

  for ($i = 0; defined($$gl_data{"locations"}[$i]); $i++) {
    if ($$gl_data{"locations"}[$i]{"id"} eq $id) {
      return $$gl_data{"locations"}[$i];
    }
  }

  print "Location $id not found\n";
  return undef;
}

sub get_current_location {
  return $gl_location;
}

sub get_current_location_id {
  return $$gl_location{"id"};
}

sub set_current_location {
  $gl_location = $_[0];
}

sub set_current_location_id {
  my $id = $_[0];

  if (defined($id)) {
    my $loc = get_location($id);
    if (defined($loc)) {
      $gl_location = $loc;
    }
  }
}

# -----------------------------------------------------------------------------
# Item and Object functions
#
# Items are static to a particular location. Objects can be moved from
# location to location, or can be carried around (put in the inventory).
#
#  - get_item($item_id) returns the item object for the given ID; the item
#    has to be in the current location
#  - get_item_elsewhere($location_id, $item_id) returns the item object for
#    the item in the specified other location.
#  - get_item_list() returns an array of item IDs in the current location.
#  - get_item_list_elsewhere($location_id) returns the array of items in
#    a different location.
#  - get_item_descr($location_id, $item_id) returns the description of the
#    item.
#
#  - get_object($object_id) returns the object object for the given ID if it
#    is in the current location or inventory, or undef otherwise.
#  - get_object_elsewhere($object_id) returns the object object regardless
#    of where the object is.
#  - get_object_list() returns an array of object IDs currently accessible
#    (in the current location, or in the inventory).
#  - get_object_location($object_id) returns the location ID for the object.
#  - get_object_descr($object_id) returns the description for the object.
#  - move_object($object_id, $to_location_id) move object to location.
#  - list_objects_in_location($location_id) returns a string describing the
#    objects in the specified location.
# -----------------------------------------------------------------------------

sub get_item {
  my $item_id = $_[0];

  return get_item_elsewhere(get_current_location_id(), $item_id);
}

sub get_item_elsewhere {
  my $location_id = $_[0];
  my $item_id = $_[1];

  my $loc = get_location($location_id);
  # The location doesn't exist, so no item
  return undef if (!defined($loc));

  # The location doesn't have items, so no item
  return undef if (!defined($$loc{"items"}));

  my $i;
  for ($i = 0; defined($$loc{"items"}[$i]); $i++) {
    if ($$loc{"items"}[$i]{"name"} eq $item_id) {
      # found it
      return $$loc{"items"}[$i];
    }
  }

  # not found
  return undef;
}

sub get_item_list {
  return get_item_list_elsewhere(get_current_location_id());
}

sub get_item_list_elsewhere {
  my $location_id = $_[0];
  my @list = ();

  my $loc = get_location($location_id);
  # The location doesn't exist, so no item
  return \@list if (!defined($loc));

  # The location doesn't have items, so no item
  return \@list if (!defined($$loc{"items"}));

  my $i;
  for ($i = 0; defined($$loc{"items"}[$i]); $i++) {
    $list[$i] = $$loc{"items"}[$i]{"name"};
  }

  return \@list;
}

sub get_item_descr {
  my $loc_id = $_[0];
  my $item_id = $_[1];

  my $item = get_item($item_id);
  if (defined($item)) {
    if (defined($$item{"get-descr"})) {
      my $value = eval($$item{"get-descr"});
      return $value;
    }
    return $$item{"descr"};
  }  

  return "I don&rsquo;t know about $item_id.";
}

# Return the object object if it is visible
sub get_object {
  my $object_id = $_[0];

  if (!defined($gl_objects{$object_id})) {
    # object doesn't exist
    return undef;
  }

  my $object_loc = $gl_objects{$object_id}{"location"};
  if (!defined($object_loc)) {
    # object has no location
    return undef;
  }

  my $loc_id = get_current_location_id();
  if ($object_loc ne $loc_id && $object_loc ne $INVENTORY) {
    # object neither in current location not in inventory
    return undef;
  }

  return get_object_elsewhere($object_id);
}

# Return the object object whereever it is located.
sub get_object_elsewhere {
  my $object_id = $_[0];

  if (defined($$gl_data{"objects"})) {
    my $i;
    for ($i = 0; defined($$gl_data{"objects"}[$i]); $i++) {
      if ($$gl_data{"objects"}[$i]{"id"} eq $object_id) {
        return $$gl_data{"objects"}[$i];
      }
    }
  }

  return undef;
}

sub get_object_list {
  my @list = ();
  my $loc_id = get_current_location_id();

  my $key;
  foreach $key (keys %gl_objects) {
    my $loc = $gl_objects{$key}{"location"};
    if ($loc eq $loc_id || $loc eq $INVENTORY) {
      push(@list, $key);
    }
  }
  return \@list;
}

sub get_object_location {
  my $object_id = $_[0];

  if (defined($gl_objects{$object_id})) {
    return $gl_objects{$object_id}{"location"};
  }

  return undef;
}

sub get_object_descr {
  my $object_id = $_[0];

  my $object = get_object($object_id);
  if (defined($object)) {
    if (defined($$object{"get-descr"})) {
      my $value = eval($$object{"get-descr"});
      return $value;
    }
    return $$object{"descr"};
  }  

  return "I don&rsquo;t know about $object_id.";
}

sub move_object {
  my $object_id = $_[0];
  my $location_id = $_[1];

  if (!defined($gl_objects{$object_id})) {
    my %empty = ();
    $gl_objects{$object_id} = \%empty;
  }

  $gl_objects{$object_id}{"location"} = $location_id;
}

sub list_objects_in_location {
  my $location_id = $_[0];

  my $list = "";
  my $key;
  foreach $key (keys %gl_objects) {
    if ($gl_objects{$key}{"location"} eq $location_id) {
      $list .= ", " if ($list ne "");
      my $obj = get_object($key);
      $list .= $$obj{"sdescr"};
    }
  }

  $list =~ s/,([^,]+)$/ and$1/;
  return $list;
}

# -----------------------------------------------------------------------------
# Global values
# -----------------------------------------------------------------------------

sub set_global {
  $gl_values{$_[0]} = $_[1];
}

sub get_global {
  if (defined($gl_values{$_[0]})) {
    return $gl_values{$_[0]};
  }
  return "";
}

sub get_time {
  return get_global('time');
}

sub set_time {
  set_global('time', $_[0]);
}

# -----------------------------------------------------------------------------
# Loading and saving
# -----------------------------------------------------------------------------

sub save {
  my %data = ();
  $data{"objects"} = \%gl_objects;
  $data{"values"} = \%gl_values;
  $data{"current-location"} = get_current_location_id();

  my $data = encode_json(\%data);

  opendir(DIR, "data") || die "Cannot scan directory data\n";
  my $fname;
  my $last = 0;
  while (defined($fname = readdir(DIR))) {
    next if ($fname =~ /^\./);
    next if (-d "data/$fname");
    if ($fname =~ /^data(\d+)\.dat$/) {
      my $nr = $1;
      if ($nr > $last) {
        $last = $nr;
      }
    }
  }
  closedir(DIR);
  $last++;
  while (length($last) < 4) {
    $last = '0' . $last;
  }

  open(FILE, ">data/data$last.dat");
  print FILE $data;
  close FILE;

  out("Saved as data$last.dat");
}

sub load {
  my $fname;
  my $last = 0;
  opendir(DIR, "data") || die "Cannot scan directory data\n";
  while (defined($fname = readdir(DIR))) {
    next if ($fname =~ /^\./);
    next if (-d "data/$fname");
    if ($fname =~ /^data(\d+)\.dat$/) {
      my $nr = $1;
      if ($nr > $last) {
        $last = $nr;
      }
    }
  }
  closedir(DIR);
  open(FILE, "<data/data$last.dat");
  my $data = "";
  while (<FILE>) {
    chomp();
    s/\r//;
    $data .= $_;
  }
  close FILE;

  my $obj = decode_json($data);
  my $key;
  foreach $key (keys $$obj{"objects"}) {
    $gl_objects{$key} = $$obj{"objects"}{$key};
  }
  foreach $key (keys $$obj{"values"}) {
    $gl_values{$key} = $$obj{"values"}{$key};
  }
  set_current_location_id($$obj{"current-location"});
}
return 1;