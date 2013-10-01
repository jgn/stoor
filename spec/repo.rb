shared_context 'repo' do
  before do
    repo = Grit::Repo.init('repo')
    File.open('repo/.git/config', 'a+') do |f|
      f.write <<-GITCONFIG.strip_heredoc
      [user]
        name = Mortimer Snerd
        email = snerd@example.com
      GITCONFIG
    end
    File.open('repo/Home.md', 'w') { |f| f.write('### Nice wiki page') }
    repo.add('repo/Home.md')
  end

  after do
    FileUtils.rm_rf 'repo'
  end
end
