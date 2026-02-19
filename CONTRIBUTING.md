# Contributing to PMKID Capture Tool

Thank you for considering contributing to the PMKID Capture Tool! This document provides guidelines and instructions for contributing.

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all. Please be respectful and professional in all interactions.

### Our Standards

- Use welcoming and inclusive language
- Be respectful of differing viewpoints
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

### Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported to the project maintainers.

## How to Contribute

### Reporting Bugs

Before submitting a bug report:
- Check the documentation to see if the issue is explained there
- Search existing issues to avoid duplicates
- Test with the latest version

When submitting a bug report, include:
- Clear, descriptive title
- Steps to reproduce
- Expected behavior
- Actual behavior
- WiFi Pineapple Nano firmware version
- Tool version
- Relevant log output
- Screenshots if applicable

### Suggesting Enhancements

Enhancement suggestions are welcome! When suggesting:
- Use a clear, descriptive title
- Provide detailed description of the enhancement
- Explain why this would be useful
- Provide examples if applicable

### Pull Requests

1. **Fork the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/iNFINITEAi2025_PiNaCoLlAdA.git
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the coding style guide
   - Add tests if applicable
   - Update documentation
   - Test on actual WiFi Pineapple Nano hardware

4. **Commit your changes**
   ```bash
   git commit -m "Add feature: description"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Open a Pull Request**
   - Provide clear description of changes
   - Reference any related issues
   - Include testing results

## Development Guidelines

### Coding Style

**Shell Scripts:**
- Use 4 spaces for indentation (no tabs)
- Use lowercase for variable names
- Use UPPERCASE for constants
- Add comments for complex logic
- Use meaningful function names
- Keep functions focused and small
- Use proper error handling
- Follow bash best practices

**Example:**
```bash
# Good
capture_pmkids() {
    local timeout=$1
    local output_file="$OUTPUT_DIR/capture_$(date +%Y%m%d_%H%M%S).pcapng"
    
    if [ -z "$timeout" ]; then
        log "ERROR" "Timeout parameter required"
        return 1
    fi
    
    # Capture logic here
}

# Avoid
capturePMKIDS() {
    TIMEOUT=$1
    output="$OUTPUT_DIR/capture.pcapng"
    # No validation
    # No error handling
}
```

### Documentation

- Update README.md for user-facing changes
- Update EXAMPLES.md for new usage patterns
- Update CHANGELOG.md following Keep a Changelog format
- Add inline comments for complex logic
- Update configuration examples
- Keep documentation in sync with code

### Testing

Before submitting:

1. **Test on WiFi Pineapple Nano**
   - Test all changed functionality
   - Test error conditions
   - Test edge cases

2. **Test Installation**
   ```bash
   ./install.sh
   ```

3. **Test Core Functions**
   ```bash
   pmkid-scan
   pmkid-quick
   pmkid-capture -h
   ```

4. **Check for Errors**
   - Review log output
   - Check for shell errors
   - Verify cleanup happens properly

5. **Test Uninstall**
   ```bash
   pmkid-uninstall
   ```

### Commit Messages

Follow conventional commits:

```
type(scope): subject

body (optional)

footer (optional)
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Test additions or changes
- `chore`: Build process or auxiliary tool changes

**Examples:**
```
feat(capture): add support for channel hopping
fix(install): correct dependency installation order
docs(readme): update installation instructions
refactor(logging): improve log message clarity
```

## Project Structure

```
iNFINITEAi2025_PiNaCoLlAdA/
├── pmkid_capture.sh    # Main capture script
├── install.sh          # Installation script
├── config.conf         # Default configuration
├── README.md           # Main documentation
├── EXAMPLES.md         # Usage examples
├── CHANGELOG.md        # Version history
├── CONTRIBUTING.md     # This file
├── LICENSE             # License information
└── .gitignore          # Git ignore rules
```

## Feature Requests

We track feature requests in GitHub Issues. When requesting:

1. **Check existing requests** to avoid duplicates
2. **Provide clear use case** explaining the need
3. **Describe expected behavior** in detail
4. **Consider implementation** if possible
5. **Label appropriately** (enhancement, feature-request)

## Priority Areas

We especially welcome contributions in:

1. **Web UI Integration**
   - Pineapple web interface module
   - Status dashboard
   - Real-time capture monitoring

2. **Performance Improvements**
   - Faster PMKID capture
   - Better success rates
   - Resource optimization

3. **Additional Features**
   - Deauth attack integration
   - Target filtering
   - Automated cracking

4. **Documentation**
   - More examples
   - Video tutorials
   - Troubleshooting guides

5. **Testing**
   - Different hardware configurations
   - Edge cases
   - Error conditions

## Questions?

- Open an issue for questions
- Tag with "question" label
- Be patient and respectful

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).

## Recognition

Contributors will be recognized in:
- README.md acknowledgments section
- Release notes
- Project documentation

Thank you for contributing to the PMKID Capture Tool!
