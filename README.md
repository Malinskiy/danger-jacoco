# danger-jacoco

**danger-jacoco** is the [Danger](https://github.com/danger/danger) plugin of 
to validate the code coverage of the files changed

## Installation

```
sudo gem install danger-jacoco
```

## Usage

Add 

```ruby
jacoco.minimum_project_coverage_percentage = 50 # default 0
jacoco.minimum_class_coverage_percentage = 75 # default 0
jacoco.files_extension = [".java"] # default [".kt", ".java"]
jacoco.report("jacoco/output/dir/", "jacoco.xml", "http://jacoco-html-reports/")
```

to your `Dangerfile` 

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.
