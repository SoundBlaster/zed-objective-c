use zed_extension_api::{self as zed, LanguageServerId, Result};

const LANGUAGE_SERVER_ID: &str = "objc-clangd";

struct ObjectiveCExtension;

impl zed::Extension for ObjectiveCExtension {
    fn new() -> Self {
        Self
    }

    fn language_server_command(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        if language_server_id.as_ref() != LANGUAGE_SERVER_ID {
            return Err(format!(
                "unknown language server: {}",
                language_server_id.as_ref()
            ));
        }

        let settings =
            zed::settings::LspSettings::for_worktree(language_server_id.as_ref(), worktree)?;
        let (path, arguments, extra_env) = settings
            .binary
            .map(|binary| (binary.path, binary.arguments, binary.env))
            .unwrap_or_default();

        let command = path.or_else(|| worktree.which("clangd")).ok_or_else(|| {
            "clangd was not found in PATH; install Xcode Command Line Tools or configure lsp.objc-clangd.binary.path"
                .to_string()
        })?;

        let args = arguments.unwrap_or_else(default_clangd_arguments);
        let mut env = worktree.shell_env();
        if let Some(extra_env) = extra_env {
            env.extend(extra_env);
        }

        Ok(zed::Command { command, args, env })
    }

    fn language_server_initialization_options(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<zed::serde_json::Value>> {
        Ok(
            zed::settings::LspSettings::for_worktree(language_server_id.as_ref(), worktree)?
                .initialization_options,
        )
    }

    fn language_server_workspace_configuration(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<zed::serde_json::Value>> {
        Ok(
            zed::settings::LspSettings::for_worktree(language_server_id.as_ref(), worktree)?
                .settings,
        )
    }
}

fn default_clangd_arguments() -> Vec<String> {
    vec![
        "--background-index".into(),
        "--enable-config".into(),
        "--header-insertion=iwyu".into(),
        "--import-insertions".into(),
        "--completion-style=detailed".into(),
    ]
}

zed::register_extension!(ObjectiveCExtension);
