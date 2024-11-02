# this is just an always working test to test that the tests work...
def test_noop_test(_args, assert)
  assert.true!(1 + 1 == 2)
end

puts '--- Running tests ---'
$gtk.reset 100
$gtk.tests.start

sleep 0.5
$gtk.request_quit
