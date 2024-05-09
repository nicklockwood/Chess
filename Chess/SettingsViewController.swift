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
    var selectedTheme: Theme {
        didSet {
            Storage.shared.boardTheme = selectedTheme.rawValue
            tableView.reloadData()
        }
    }
    var onThemeSelect: ((Theme) -> ())?
    
    init(selectedTheme: Theme?) {
        self.selectedTheme = selectedTheme ?? .classic
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        print("SettingsViewController deinit")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Board Themes"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Theme.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let theme = Theme.allCases[indexPath.row]
        cell.textLabel?.text = theme.rawValue
        cell.accessoryType = selectedTheme == theme ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTheme = Theme.allCases[indexPath.row]
        onThemeSelect?(selectedTheme)
    }
}
