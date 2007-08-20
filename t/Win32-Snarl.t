# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-Snarl.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;
BEGIN { use_ok('Win32::Snarl') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $version = Win32::Snarl::GetVersion();
ok ($version >= 65542, 'Get Version');

my $message_id = Win32::Snarl::ShowMessage('Win32::Snarl', 'Testing');
ok ($message_id, 'Show Message');

# have to wait for the message to show before we can hide it
sleep 1;

ok (Win32::Snarl::IsMessageVisible($message_id), 'Visible');
ok (defined Win32::Snarl::HideMessage($message_id), 'Hide Message');
ok (!Win32::Snarl::IsMessageVisible($message_id), 'Not Visible');

# not the best tests, need human confirmation really
ok (defined Win32::Snarl::RegisterConfig(0, 'Win32::Snarl', 0), 'Register Config');
ok (defined Win32::Snarl::RevokeConfig(0), 'Revoke Config');
ok (defined Win32::Snarl::RegisterConfig2(0, 'Win32::Snarl', 0), 'Register Config 2');
ok (defined Win32::Snarl::RegisterAlert('Win32::Snarl', 'Test Message'), 'Register Alert');
ok (defined Win32::Snarl::RevokeConfig(0), 'Revoke Config (again)');

