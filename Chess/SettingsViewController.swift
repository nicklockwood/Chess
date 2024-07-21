//
//  SettingsViewController.swift
//  Chess
//
//  Created by Khislatjon Valijonov on 09/05/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)

    var onThemeSelect: ((Theme) -> Void)?
    var onFlipBlackWhenHuman: ((Bool) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
    }

    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    enum Section: Int, CaseIterable {
        case settings
        case themes
    }

    func numberOfSections(in _: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .settings:
            return nil
        case .themes:
            return "Board Themes"
        case nil:
            return nil
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .settings:
            return 1
        case .themes:
            return Theme.allCases.count
        case nil:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch Section(rawValue: indexPath.section) {
        case .settings:
            cell.textLabel?.text = "Flip black pieces when human"
            let toggle = UISwitch()
            toggle.isOn = Storage.shared.flipBlackWhenHuman
            toggle.addTarget(self, action: #selector(toggleFlipBlack), for: .valueChanged)
            cell.accessoryView = toggle
        case .themes:
            let theme = Theme.allCases[indexPath.row]
            cell.textLabel?.text = theme.rawValue
            let selected = Storage.shared.boardTheme == theme.rawValue
            cell.accessoryType = selected ? .checkmark : .none
            cell.accessoryView = nil
        case nil:
            break
        }
        return cell
    }

    @objc private func toggleFlipBlack() {
        let cell = tableView.cellForRow(at: IndexPath(item: 0, section: Section.settings.rawValue))
        let selected = (cell?.accessoryView as? UISwitch)?.isOn ?? false
        Storage.shared.flipBlackWhenHuman = selected
        onFlipBlackWhenHuman?(selected)
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section) {
        case .settings:
            break
        case .themes:
            let selectedTheme = Theme.allCases[indexPath.row]
            Storage.shared.boardTheme = selectedTheme.rawValue
            tableView.reloadSections([Section.themes.rawValue], with: .none)
            onThemeSelect?(selectedTheme)
        case nil:
            break
        }
    }
}
