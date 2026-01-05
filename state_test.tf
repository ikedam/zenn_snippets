resource "google_secret_manager_secret" "state_test_source" {
  secret_id = "${var.basename}-state-test-source"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "state_test_source" {
  secret = google_secret_manager_secret.state_test_source.id

  secret_data_wo         = "state-test-data"
  secret_data_wo_version = 1
}

# データソースを使ったコピー
resource "google_secret_manager_secret" "state_test_target_nonephemeral" {
  secret_id = "${var.basename}-state-test-target-nonephemeral"

  replication {
    auto {}
  }
}

data "google_secret_manager_secret_version" "state_test_source_by_datasource" {
  secret = google_secret_manager_secret.state_test_source.id

  depends_on = [google_secret_manager_secret_version.state_test_source]
}

resource "google_secret_manager_secret_version" "state_test_target_nonephemeral" {
  secret = google_secret_manager_secret.state_test_target_nonephemeral.id

  secret_data_wo         = data.google_secret_manager_secret_version.state_test_source_by_datasource.secret_data
  secret_data_wo_version = data.google_secret_manager_secret_version.state_test_source_by_datasource.version
}

# ephemeral リソースを使ったコピー
resource "google_secret_manager_secret" "state_test_target_ephemeral" {
  secret_id = "${var.basename}-state-test-target-ephemeral"

  replication {
    auto {}
  }
}

ephemeral "google_secret_manager_secret_version" "state_test_source_by_ephemeral" {
  secret = google_secret_manager_secret.state_test_source.id

  depends_on = [google_secret_manager_secret_version.state_test_source]
}

resource "google_secret_manager_secret_version" "state_test_target_ephemeral" {
  secret = google_secret_manager_secret.state_test_target_ephemeral.id

  secret_data_wo = ephemeral.google_secret_manager_secret_version.state_test_source_by_ephemeral.secret_data

  # ephemeral リソースの出力を write-only argument 以外に設定できない。
  secret_data_wo_version = 1
}
