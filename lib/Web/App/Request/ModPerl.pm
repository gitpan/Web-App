package Web::App::Request::ModPerl;

# use Web::App::Common;

use Web::App::Request;
use base qw(Web::App::Request);

use Class::Easy;

return 1
	unless $ENV{MOD_PERL};

our $MOD_PERL = 1;
$MOD_PERL = $ENV{MOD_PERL_API_VERSION}
	if $ENV{MOD_PERL_API_VERSION};

our $COOKIE_PACK  = 'Apache::Cookie';
our $CONST_PACK   = 'Apache::Constants';
our $SIZE_PACK    = 'Apache::SizeLimit';
our $SERVER_PACK  = 'Apache';

if ($MOD_PERL == 2) {
	$COOKIE_PACK  = 'Apache2::Cookie';
	$CONST_PACK   = 'Apache2::Const';
	$SIZE_PACK    = 'Apache2::SizeLimit';
	
	try_to_use ('Apache2::RequestUtil');
	try_to_use ('Apache2::Request');
	try_to_use ('Apache2::ServerUtil');
	
	$SERVER_PACK = 'Apache2::ServerUtil';
	
} elsif ($MOD_PERL == 1) {
	try_to_use ('Apache');
	try_to_use ('Apache::Request');
}

try_to_use ($COOKIE_PACK);
try_to_use ($CONST_PACK);
$CONST_PACK->compile ('-compile', ':common');

try_to_use ($SIZE_PACK);
try_to_use ($SERVER_PACK);

$SIZE_PACK::MAX_PROCESS_SIZE  = 256*1024;  # 256MB
$SIZE_PACK::MIN_SHARE_SIZE    = 128*1024;  # 128MB
$SIZE_PACK::MAX_UNSHARED_SIZE = 160*1024;  # 160MB

my $dir_config = $SERVER_PACK->server->dir_config;

has 'http_code', is => 'rw', default => $CONST_PACK::DONE;

sub test ($$) {
	my $class = shift;
	my $r     = shift;
	
	foreach (sort keys %ENV) {
		print "$_ => $ENV{$_}<br/>\n";
	}
}


sub r {
	my $r;
	if ($MOD_PERL == 1) {
		$r = Apache->request;
	} elsif ($MOD_PERL == 2) {
		$r = Apache2::RequestUtil->request;
	} else {
		die;
	}
	
	die unless defined $r;
	
	return $r;
}

sub r_method {
	my $object = shift;
	my $method = shift;
	
	if ($MOD_PERL == 1) {
		$object->$method (@_);
	} elsif ($MOD_PERL == 2) {
		$object->$method (@_, r());
	}
}

sub request {
	if ($MOD_PERL == 1) {
		return Apache::Request->new(r());
	} elsif ($MOD_PERL == 2) {
		return Apache2::Request->new(r());
	}
}

sub send_headers {
	my $self = shift;
	my $headers = shift;
	
	foreach (@$headers) {
		my ($key, $val) = (split ': ', $_, 2);
		
		$val =~ s/[\r\n]+//g;
		
		if ($key =~ /content-type/i) {
			r->content_type ($val);
		} else {
			if ($key =~ /location/i) {
				debug "redirect detected";
				debug "ok => ", $CONST_PACK::OK, ', redirect => ', $CONST_PACK::REDIRECT;
				$self->http_code ($CONST_PACK::REDIRECT);
			}
			r->headers_out->{$key} = $val;
		}
	}
}

sub send_content {
	my $self    = shift;
	my $content = shift;
	
	debug "content output";
	
	utf8::decode ($content);
	
	r->print ($content);
}


sub status {
	my $self = shift;
	
	debug "code is: " . $self->http_code;
	
	return $self->http_code;
}

1;