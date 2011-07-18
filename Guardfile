guard 'rspec', all_after_pass: false, cli: '--color --format nested' do
  watch(%r{(^|/)\.'})                 {}  # ignore dot files
  watch(%r{^lib/(.+)\.rb})            { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^spec/(.+)_spec\.rb})      { |m| m[0] }
  watch('spec/spec_helper.rb')        { 'spec' }
  watch(%r{^spec/factories/(.+)\.rb}) { 'spec' }
  watch(%r{^spec/fixtures/.+})        { 'spec' }
end
