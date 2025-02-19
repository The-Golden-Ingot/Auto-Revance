const core = require('@actions/core');

try {
  // Define valid app options for each provider
  const providerApps = {
    revanced: ['googlephotos', 'soundcloud'],
    anddea: ['youtube'],
    piko: ['twitter'],
    experiments: ['instagram']
  };

  // Get the selected provider
  const provider = core.getInput('provider');
  
  // Get valid apps for the provider
  const validApps = providerApps[provider] || [];
  
  // Set the output
  core.setOutput('valid-apps', validApps);
  
  // Update the workflow input options
  if (validApps.length > 0) {
    const notice = [
      `Valid apps for ${provider}:`,
      ...validApps.map(app => `✓ ${app}`),
      '',
      'Instructions:',
      '1. Select your desired apps using the checkboxes above',
      '2. Only the checkboxes for apps compatible with your chosen provider will be validated',
      `3. You must select at least one app compatible with ${provider}`
    ].join('\n');
    
    core.notice(notice);
  } else {
    core.setFailed(`No valid apps found for provider: ${provider}`);
  }
} catch (error) {
  core.setFailed(error.message);
} 