
lambda { |stdout,stderr,status|
  output = stdout + stderr
  return :red   if /^Tests run: (\d+),(\s)+Failures: (\d+)/.match(output)
  return :green if /^OK \((\d+) test/.match(output)
  return :amber
}
