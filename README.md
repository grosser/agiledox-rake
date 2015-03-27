==Goal=
Agiledox is a simple rake script, to *transform your tests/specs into documentation*. 

There are to many versions and hacks of the [http://web.archive.org/web/20070814020139/http://www.reevoo.com/blogs/bengriffiths/2005/06/24/a-test-by-any-other-name/ original agiledox task] out there, so i grabbed them all, added sugar+refactoring+rspec and put them into one task.

Contributers welcome!

==Install=
Drop into lib/tasks.

==Output=
{{{
A User:
  - should not be valid without login
  - should not be valid without email
...
A Users Controller's:
  'new' action:
    - should succeed
  'edit' action:
    - should succeed
...
A /users/edit:
  - sould show errors
  - sould have enought rows
...
A Users Helper:
...
}}}

==Syntax=
{{{
rake dox
rake dox:test => all files matching _test.rb
rake dox:test:units
rake dox:spec:models
...
rake spec:dox => all files matching _spec.rb
rake spec:models:dox
rake test:functionals:dox
...

test=> units,functionals,integration
spec=> models,controllers,views,helpers
}}}

==Options=
Set options in the agiledox_options.

===:write=
Default: OFF

Write the output as comment to the tested file(models/controllers only)
{{{
#AGILEDOX !WILL BE OVERWRITTEN!
#A User:
#  - should create valid user
#  - should stop invalid
#  - should not allow duplicated fields
#  - should be activated by default
#  - should only find activated
#AGILEDOX END
class User < ActiveRecord::Base
...
end
}}}

===:list_nested_actions=
Default: ON

*test/functionals only:* use the Test::Rails sheme of naming your tests: *`test_{action}_should`*....
{{{
An Users Controller's:
  'create' action:
    - should set a notice
    - should redirect to user on success
    - should redirect to index on failure
...
}}}


==TODO=
 * nothing, any ideas ?


Anyone that want credit for his idea/part of agiledox -> email.

==Changelog=
0.4 - test:dox / and spec:dox process any file in any folder matching `_test.rb` in test/spec folders + simplified code

0.3 - options + change from test:dox:units to test:units:dox + redundancy dried out

0.2 - rspec support + rake test:dox / rake spec:dox

0.1 - initial test only
