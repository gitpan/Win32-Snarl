package Win32::Snarl;

use 5.008000;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.01';

use Carp;
use Win32::GUI;

# Windows message number
use constant WM_COPYDATA => 0x4a;

# Snarl Commands
use constant SNARL_SHOW                     => 1;
use constant SNARL_HIDE                     => 2;
use constant SNARL_UPDATE                   => 3;
use constant SNARL_IS_VISIBLE               => 4;
use constant SNARL_GET_VERSION              => 5;
use constant SNARL_REGISTER_CONFIG_WINDOW   => 6;
use constant SNARL_REVOKE_CONFIG_WINDOW     => 7;
use constant SNARL_REGISTER_ALERT           => 8;
use constant SNARL_REVOKE_ALERT             => 9;
use constant SNARL_REGISTER_CONFIG_WINDOW_2 => 10;
use constant SNARL_EX_SHOW                  => 32;

# Global Events
use constant SNARL_LAUNCHED       => 1;
use constant SNARL_QUIT           => 2;
use constant SNARL_ASK_APPLET_VER => 3;
use constant SNARL_SHOW_APP_UI    => 4;

# Notification Events
use constant SNARL_NOTIFICATION_CLICKED   => 32;
use constant SNARL_NOTIFICATION_TIMED_OUT => 33;
use constant SNARL_NOTIFICATION_ACK       => 34;
use constant SNARL_NOTIFICATION_CANCELLED => 32;

# Error Responses
use constant M_NOT_IMPLEMENTED => 0x80000001;
use constant M_OUT_OF_MEMORY   => 0x80000002;
use constant M_INVALID_ARGS    => 0x80000003;
use constant M_NO_INTERFACE    => 0x80000004;
use constant M_BAD_POINTER     => 0x80000005;
use constant M_BAD_HANDLE      => 0x80000006;
use constant M_ABORTED         => 0x80000007;
use constant M_FAILED          => 0x80000008;
use constant M_ACCESS_DENIED   => 0x80000009;
use constant M_TIMED_OUT       => 0x8000000a;
use constant M_NOT_FOUND       => 0x8000000b;
use constant M_ALREADY_EXISTS  => 0x8000000c;

# C Struct Formats
use constant PACK_FORMAT    => 'l4a1024a1024a1024';
use constant PACK_FORMAT_EX => 'l4a1024a1024a1024 a1024a1024a1024l2';

# Subroutines

sub _Dump {
	my ($mem) = @_;
	
	my $i = 0;
	map (++$i % 320 ? ($i % 16 ? "$_ " : "$_\n") : "$_\n\n", unpack('H2' x length($mem), $mem)), length($mem) % 16 ? "\n" : '';
}

sub _SendMessage {
    my ($struct) = @_;
    
    my $hwnd = GetSnarlWindow() or return;
    my $cd = pack('L2P', 2, length($struct), $struct);
    
    my $res = Win32::GUI::SendMessage($hwnd, WM_COPYDATA, 0, $cd);
    
    if (my $err = _Error($res)) {
	    carp $err;
	    return undef;
    }
    
    return $res;
}

sub _MakeString {
	my ($data) = @_;
	
	substr($data, 0, 1023);	
}

sub _MakeStruct {
	my %params = @_;
	
	my @fields = qw[command id timeout data title text icon];
		
	$params{$_} ||= 0 for qw[command id timeout data];
	$params{$_} = _MakeString($params{$_} || '') for qw[title text icon];
	
	pack PACK_FORMAT, @params{@fields};
}

sub _MakeStructEx {
	my %params = @_;
	
	my @fields = qw[command id timeout data title text icon
	                class extra extra2 reserved1 reserved2];
		
	$params{$_} ||= 0 for qw[command id timeout data reserved1 reserved2];
	$params{$_} = _MakeString($params{$_} || '') for qw[title text icon class extra extra2];
	
	pack PACK_FORMAT_EX, @params{@fields};
}

sub _Error {
	my ($value) = @_;
	
	$value += 0xffffffff if $value < 0;
	
	my %errors = (
		0x80000001 => 'Not Implemented',
		0x80000002 => 'Out of Memory',
		0x80000003 => 'Invalid Arguments',
		0x80000004 => 'No Interface',
		0x80000005 => 'Bad Pointer',
		0x80000006 => 'Bad Handle',
		0x80000007 => 'Aborted',
		0x80000008 => 'Failed',
		0x80000009 => 'Access Denied',
		0x8000000a => 'Timed Out',
		0x8000000b => 'Not Found',
		0x8000000c => 'Already Exists',
	);
	
	return $errors{$value};
}

sub HideMessage {
	my ($id) = @_;
	
	_SendMessage(_MakeStruct(
		command => SNARL_HIDE,
		id => $id,
	));
}

sub IsMessageVisible {
	my ($id) = @_;
	
	_SendMessage(_MakeStruct(
		command => SNARL_IS_VISIBLE,
		id => $id,
	));
}

sub RegisterAlert {
	my ($application, $class) = @_;
	
	_SendMessage(_MakeStruct(
		command => SNARL_REGISTER_ALERT,
		title => $application,
		text => $class,
	));
}

sub RegisterConfig {
	my ($hwnd, $application, $reply) = @_;
	
	_SendMessage(_MakeStruct(
		command => SNARL_REGISTER_CONFIG_WINDOW,
		id => $reply,
		data => $hwnd,
		title => $application,
	));
}

sub RegisterConfig2 {
	my ($hwnd, $application, $reply, $icon) = @_;
	
	_SendMessage(_MakeStruct(
		command => SNARL_REGISTER_CONFIG_WINDOW_2,
		id => $reply,
		data => $hwnd,
		title => $application,
		icon => $icon,
	));
}

sub RevokeConfig {
	my ($hwnd) = @_;
	
	_SendMessage(_MakeStruct(
		command => SNARL_REVOKE_CONFIG_WINDOW,
		data => $hwnd,
	));
}

sub ShowMessage {
	my ($title, $text, $timeout, $icon, $hwnd, $reply) = @_;
	
	_SendMessage(_MakeStructEx(
		command => SNARL_SHOW,
		id => $reply,
		timeout => $timeout,
		data => $hwnd,
		title => $title,
		text => $text,
		icon => $icon,
	));
}

sub ShowMessageEx {
	my ($class, $title, $text, $timeout, $icon, $hwnd, $reply, $sound) = @_;
	
	_SendMessage(_MakeStructEx(
		command => SNARL_EX_SHOW,
		id => $reply,
		timeout => $timeout,
		data => $hwnd,
		title => $title,
		text => $text,
		icon => $icon,
		class => $class,
		extra => $sound,
	));
}

sub UpdateMessage {
	my ($id, $title, $text, $icon) = @_;
	
	_SendMessage(_MakeStruct(
		command => SNARL_UPDATE,
		id => $id,
		title => $title,
		text => $text,
		icon => $icon,
	));
}

sub GetSnarlWindow {
	# no parameters

	my $hwnd = Win32::GUI::FindWindow('', 'Snarl');
	return unless Win32::GUI::IsWindow($hwnd);
	
	return $hwnd;
}

sub GetVersion {
	# no parameters
	
	_SendMessage(_MakeStruct(
		command => SNARL_GET_VERSION,
	));
}

1;

__END__

=head1 NAME

Win32::Snarl - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Win32::Snarl;
  
	Win32::Snarl::ShowMessage('Perl', 'Perl is awesome, so is Snarl.');
	
	my $msg_id = Win32::Snarl::ShowMessage('Time', 'The time is now ' . (scalar localtime));
	while (Win32::Snarl::MessageIsVisible($msg_id) {
		sleep 1;
		Win32::Snarl::UpdateMessage($msg_id, 'Time', 'The time is no ' . (scalar localtime));
	}

=head1 DESCRIPTION

Snarl E<lt>http://www.fullphat.net/E<gt> is a notification system inspired by 
Growl E<lt>http://growl.info/E<gt> for Macintosh that lets applications display
nice alpha-blended messages on the screen.

C<Win32::Snarl> is the perl interface to Snarl because the people at fullphat 
seem not to care about perl :'(.

=head1 SEE ALSO

C<Win32::GUI> For Windows API Calls
Snarl Documentation E<lt>http://www.fullphat.net/dev/E<gt>

=head1 AUTHOR

Alan Berndt, E<lt>alan@eatabrick.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Alan Berndt

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
