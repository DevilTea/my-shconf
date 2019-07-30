#!/bin/sh

REPO_URL="https://github.com/DevilTea/my-shconf"
REPO_NAME="my-shconf"
REPO_VERSION="v1.0"

# Install application
installApp() {
    # Check counts of arguments
    if [ $# -lt 1 ]
    then
        return -1
    fi
    
    # Decide the package manager to be used
    kernel=$(uname -s)
    if [ "$kernel" = "Darwin" ]
    then
        if ! command -v brew > /dev/null 2>&1
        then
            echo "To run this install script, Homebrew is needed to be installed."
            if askQuestion "Would you like to install Homebrew?" "Yn"
            then
                /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
                result=$?
                if [ $result -ne 0 ]
                then
                    return $result
                fi
            fi
        fi
        # macOS with brew
        brew install $1
        return $?
        
    elif [ "$kernel" = "FreeBSD" ]
    then
        if command -v pkg > /dev/null 2>&1
        then
            # FreeBSD with pkg
            sudo pkg install -y $1
            return $?
        else
            echo "To run this install script, PKGNG is needed to be installed."
            echo See this: https://wiki.freebsd.org/pkgng
            return 87
        fi
        
    elif [ "$kernel" = "Linux" ]
    then
        if command -v apt-get > /dev/null 2>&1
        then
            # Debian/Ubuntu with apt-get
            sudo apt-get install -y $1
            return $?
        elif command -v dnf > /dev/null 2>&1
        then
            # Fedora/CentOS with dnf
            sudo dnf install -y $1
            return $?
        elif command -v yum > /dev/null 2>&1
        then
            # Fedora/CentOS with yum
            sudo yum install -y $1
            return $?
        elif command -v ipkg > /dev/null 2>&1
        then
            # Embedded Device with ipkg
            sudo ipkg install $1
            return $?
        elif command -v opkg > /dev/null 2>&1
        then
            # Embedded Device with opkg
            sudo opkg install $1
            return $?
        fi
    fi 
}


# Ask question
askQuestion() {
    # Check counts of arguments
    if [ $# -lt 2 ]
    then
        return -1
    fi

    # Ask
    if [ "$2" = "Yn" ]
    then
        # Display question with default answer yes
        printf "$1 [Y/n] "; read ans
        case $ans in
            [Nn*])
                return 1
                ;;
            *)
                return 0
                ;;
        esac
    else
        # Display question with default answer no
        printf "$1 [y/N] "; read ans
        case $ans in
            [Yy*]) 
                return 0
                ;;
            *) 
                return 1
                ;;
        esac
    fi
}

# Apply config of zsh
applyZshConfig() {
    # Require oh-my-zsh
    if ! [ -d ~/.oh-my-zsh ]
    then
        if command -v curl > /dev/null 2>&1
        then
            sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's/env zsh -l//g')"
        else
            sh -c "$(wget -qO- https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's/env zsh -l//g')"
        fi
    fi
    # Install powerlevel9k
    if ! [ -d ~/.oh-my-zsh/custom/themes/powerlevel9k ]
    then
        git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
    fi
    # Install zsh-autosuggestions
    if ! [ -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]
    then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi
    # Install zsh-syntax-highlighting
    if ! [ -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]
    then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi
    if [ -f ~/.zshrc ] && askQuestion "Would you like to backup your original zsh config file?" "Yn"
    then
        mv ~/.zshrc ~/.zshrc.bak
    fi
    echo "source ~/.$REPO_NAME/configs/zsh/default.zshrc" >> ~/.zshrc
    echo "DEFAULT_USER=$USER" >> ~/.zshrc
}

# Apply config of vim
applyVimConfig() {
    if [ -f ~/.vimrc ] && askQuestion "Would you like to backup your original vim config file?" "Yn"
    then
        mv ~/.vimrc ~/.vimrc.bak
    fi
    echo "source ~/.$REPO_NAME/configs/vim/default.vimrc" >> ~/.vimrc
}

# Apply config of tmux
applyTmuxConfig() {
    if [ -f ~/.tmux.conf ] && askQuestion "Would you like to backup your original tmux config file?" "Yn"
    then
        mv ~/.tmux.conf ~/.tmux.conf.bak
    fi
    echo "source ~/.$REPO_NAME/configs/tmux/default.tmux.conf" >> ~/.tmux.conf
}

main() {
    # Check git
    if ! command -v git > /dev/null 2>&1
    then
        echo "To run this install script, git is needed to be installed."
        if askQuestion "Would you like to install git?" "Yn"
        then
            installApp git
        fi
    fi

    # Remove old one
    if [ -d ~/.$REPO_NAME ]
    then
        rm -rf ~/.$REPO_NAME
    fi
    
    # Clone repo to local
    git clone $REPO_URL ~/.$REPO_NAME
    if [ $? != 0 ]
    then
        echo "Failed to clone $REPO_NAME."
        return 1
    fi
    cd ~/.$REPO_NAME
    git checkout $REPO_VERSION

    # Ask for installing
    todo=''
    apps='zsh vim tmux'
    for app in $apps
    do
        if ! command -v $app > /dev/null 2>&1
        then
            msg="Would you like to install and apply configs about $app?"
        else
            msg="Would you like to apply configs about $app?"
        fi

        if askQuestion "$msg" "Yn"
        then
            todo="$todo $app"
        fi
    done
    if [ "$todo" != "" ]
    then
        installApp $todo
    fi
    
    if echo $todo | grep zsh > /dev/null
    then
        applyZshConfig
    fi
    
    if echo $todo | grep vim > /dev/null
    then
        applyVimConfig
    fi
    
    if echo $todo | grep tmux > /dev/null
    then
        applyTmuxConfig
    fi
    
    # Finished
    echo
    echo Done! Have fun!
}

main
