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
jacoco.minimum_coverage_percentage=80
jacoco.report "path/to/jacoco.xml"
```

to your `Dangerfile` 

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.
